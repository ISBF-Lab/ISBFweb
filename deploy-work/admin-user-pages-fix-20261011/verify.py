"""Check only the affected personal pages with one temporary native login session."""

import json
import os
import subprocess

from build import ART, DOCKER, ROOT, output, save_json

TEST_CONTAINER = "isbf_admin_permissions_test_20261011"
DESCRIPTION = "ISBF user pages fix verification 20261011 production"

CREATE_SESSION = r"""
require "json"
description=DESCRIPTION
raise "Verification sessions already exist" if UserAuthToken.where("user_agent LIKE ?", description + " %").exists?
moderator=User.where(admin:false,moderator:true,active:true,approved:true).where("id>0").order(:id).find{|user| !user.suspended? && !user.silenced?}
raise "Verification administrator unavailable" unless moderator
result={}
UserAuthToken.transaction do
 token=UserAuthToken.generate!(user_id:moderator.id,user_agent:description+" moderator",client_ip:"127.0.0.1")
 env=Rails.application.env_config.merge(Rack::MockRequest.env_for("https://isbf-one.com/"))
 jar=ActionDispatch::Request.new(env).cookie_jar
 Auth::DefaultCurrentUserProvider.new(env).set_auth_cookie!(token.unhashed_auth_token,moderator,jar)
 cookie_name=Auth::DefaultCurrentUserProvider::TOKEN_COOKIE
 cookie=CGI.escape(jar[cookie_name])
 check_env=env.merge("HTTP_COOKIE"=>cookie_name+"="+cookie)
 raise "Verification cookie unavailable" unless CurrentUser.lookup_from_env(check_env)&.id==moderator.id
 result={id:moderator.id,username:moderator.username,cookie:cookie,cookie_name:cookie_name,token_id:token.id}
end
puts JSON.generate(result)
"""

BROWSER = r"""
const fs = require('node:fs');
const assert = require('node:assert/strict');
const { chromium } = require('playwright');
const [credentialsPath,reportPath,productionIp,ownerUid,ownerGid] = process.argv.slice(2);
process.umask(0o077);
const actor = JSON.parse(fs.readFileSync(credentialsPath,'utf8'));
const address = 'https://isbf-one.com';
const report = {passed:false,pages:[],staff_information_responses:[],javascript_errors:[],broken_assets:[]};

(async () => {
 const browser = await chromium.launch({executablePath:'/task-tools/browser/chrome',headless:true,args:['--no-sandbox','--disable-dev-shm-usage','--host-resolver-rules=MAP isbf-one.com '+productionIp]});
 try {
  const context = await browser.newContext({viewport:{width:1280,height:900},locale:'zh-CN'});
  await context.addCookies([{name:actor.cookie_name,value:actor.cookie,url:address,httpOnly:true,secure:true,sameSite:'Lax',expires:Date.now()/1000+900}]);
  await context.route('**/*',async route => {
   const request=route.request(),url=new URL(request.url());
   if(url.origin!==address)return route.continue();
   if(!['GET','HEAD'].includes(request.method())) {
    if(url.pathname==='/srv/pv')return route.fulfill({status:204});
    if(url.pathname.startsWith('/message-bus/'))return route.fulfill({status:200,contentType:'application/json',body:'[]'});
    return route.abort('blockedbyclient');
   }
   if(['/assets/','/theme-javascripts/','/stylesheets/','/extra-locales/','/uploads/','/user_avatar/','/plugins/'].some(prefix=>url.pathname.startsWith(prefix)))return route.continue();
   const headers={...request.headers()};delete headers['discourse-logged-in'];
   return route.continue({headers});
  });
  const page=await context.newPage();page.setDefaultTimeout(90000);
  page.on('pageerror',error=>report.javascript_errors.push(error.message));
  page.on('response',response=>{
   const path=new URL(response.url()).pathname;
   if(path.endsWith('/staff-info.json'))report.staff_information_responses.push(response.status());
   if(response.status()>=400 && ['script','stylesheet'].includes(response.request().resourceType()))report.broken_assets.push({path,status:response.status()});
  });
  const base='/u/'+encodeURIComponent(actor.username.toLowerCase());
  for(const [name,suffix] of [['profile','/summary'],['bookmarks','/activity/bookmarks'],['notifications','/notifications'],['preferences','/preferences/profile'],['messages','/messages']]) {
   const response=await page.goto(address+base+suffix,{waitUntil:'domcontentloaded',timeout:120000});
   assert.equal(response.status(),200,name+' document response');
   await page.locator('.user-main').waitFor();
   const path=new URL(page.url()).pathname;
   assert.ok(path.startsWith(base+suffix),name+' remained accessible');
   assert.equal(await page.locator('.exception-page,.error-page').count(),0,name+' has no error page');
   report.pages.push({name,document_status:200,personal_page_rendered:true});
  }
  assert.deepEqual(report.javascript_errors,[]);
  assert.deepEqual(report.broken_assets,[]);
  report.passed=true;
  await context.close();
 } catch(error) {
  report.error_type=error.name;
  report.error=error.message.replaceAll(actor.username,'<user>');
  throw new Error(report.error);
 } finally {
  fs.writeFileSync(reportPath,JSON.stringify(report,null,2)+'\n');
  fs.chownSync(reportPath,Number(ownerUid),Number(ownerGid));fs.chmodSync(reportPath,0o600);
  await browser.close();
 }
})().catch(error=>{console.error(error.message);process.exitCode=1;});
"""


def verify():
    command = DOCKER + ["exec", "-u", "discourse", "-w", "/var/www/discourse", "-e", "RAILS_ENV=production", "isbf_app", "bin/rails", "runner"]
    credentials = None
    credential_file = ART / "production-browser-credentials.json"
    report_file = ART / "production-browser-report.json"
    try:
        credentials = json.loads(output(command + [CREATE_SESSION.replace("DESCRIPTION", repr(DESCRIPTION))]))
        with credential_file.open("w") as handle:
            os.fchmod(handle.fileno(), 0o600)
            json.dump(credentials, handle)
        production_ip = output(DOCKER + ["inspect", "isbf_app", "--format", "{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}} "])
        subprocess.run(DOCKER + ["exec", "-u", "root", "-i", "-w", "/src", "-e", "LD_LIBRARY_PATH=/task-tools/browser-libs", TEST_CONTAINER, "node", "-", str(credential_file).replace(str(ROOT), "/src"), str(report_file).replace(str(ROOT), "/src"), production_ip, str(os.getuid()), str(os.getgid())], input=BROWSER, text=True, check=True)
    finally:
        credential_file.unlink(missing_ok=True)
        if credentials:
            cleanup = "owners={TOKEN_ID => USER_ID}; UserAuthToken.where(id: TOKEN_ID).find_each { |token| raise \"Verification token owner changed\" unless token.user_id == owners.fetch(token.id); raise \"Verification token provenance unavailable\" unless UserAuthTokenLog.where(user_auth_token_id: token.id, action: \"generate\").where(\"user_agent LIKE ?\", DESCRIPTION + \" %\").exists?; token.destroy! }; raise \"Verification session cleanup failed\" if UserAuthToken.where(id: TOKEN_ID).exists?; puts \"Temporary personal-page verification session removed\""
            cleanup = cleanup.replace("TOKEN_ID", str(credentials["token_id"])).replace("USER_ID", str(credentials["id"])).replace("DESCRIPTION", repr(DESCRIPTION))
            print(output(command + [cleanup]), flush=True)
            if report_file.exists():
                report = json.loads(report_file.read_text())
                report["verification_sessions_removed"] = True
                save_json(report_file, report)


if __name__ == "__main__":
    verify()
