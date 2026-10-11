"""Exercise the real theme and permission page using temporary browser sessions."""

import json
import os
from pathlib import Path
import subprocess
import sys

from build import ART, DOCKER, output, save_json

TEST_CONTAINER = "isbf_admin_permissions_test_20261011"

BROWSER = r"""
const fs = require('fs');
const assert = require('node:assert/strict');
const { chromium } = require('playwright');
const [mode, address, credentialsPath, reportPath, productionIp, ownerUid, ownerGid] = process.argv.slice(2);
process.umask(0o077);
const credentials = JSON.parse(fs.readFileSync(credentialsPath, 'utf8'));
const origin = new URL(address).origin;
const report = {passed:false, mode, viewports:[], actors:[]};
const args = ['--no-sandbox','--disable-dev-shm-usage'];
if (mode === 'production') args.push('--host-resolver-rules=MAP isbf-one.com '+productionIp);

(async () => {
 const browser = await chromium.launch({executablePath:'/task-tools/browser/chrome',headless:true,args});
 try {
  async function contextFor(actor, viewport, write = false) {
   const context = await browser.newContext({viewport:{width:viewport.width,height:viewport.height},isMobile:viewport.name==='mobile',hasTouch:viewport.name==='mobile',colorScheme:viewport.name==='mobile'?'dark':'light',locale:'zh-CN'});
   await context.addCookies([{name:actor.cookie_name,value:actor.cookie,url:address,httpOnly:true,secure:mode==='production',sameSite:'Lax',expires:Date.now()/1000+900}]);
   const errors=[], brokenAssets=[];
   await context.route('**/*',async route => {
    const request=route.request(), url=new URL(request.url());
    if(url.origin !== origin) return route.continue();
    if(!['GET','HEAD'].includes(request.method())) {
     if(write && url.pathname === '/admin/site_settings/bulk_update') {
      return route.continue();
     }
     if(url.pathname==='/srv/pv') return route.fulfill({status:204});
     if(url.pathname.startsWith('/message-bus/')) return route.fulfill({status:200,contentType:'application/json',body:'[]'});
     return route.abort('blockedbyclient');
    }
    if(/^\/(assets|theme-javascripts|stylesheets|extra-locales|uploads|user_avatar|plugins)\//.test(url.pathname)) return route.continue();
    const headers={...request.headers()};
    delete headers['discourse-logged-in'];
    return route.continue({headers});
   });
   const page=await context.newPage();
   page.setDefaultTimeout(90000);
   page.on('pageerror',error=>errors.push(error.message));
   page.on('response',response=>{
    if(response.status()>=400 && ['script','stylesheet'].includes(response.request().resourceType())) brokenAssets.push({path:new URL(response.url()).pathname,status:response.status()});
   });
   return {context,page,errors,brokenAssets};
  }
  async function read(page,path) {
   return page.evaluate(async path=>{
    const response=await fetch(path);
    const text=await response.text();
    let body;try{body=JSON.parse(text);}catch{body=null;}
    return {status:response.status,body};
   },path);
  }
  function denied(result) {assert.ok([403,404].includes(result.status),'Expected denied access, received '+result.status);}
  for(const viewport of [{name:'desktop',width:1365,height:900},{name:'mobile',width:390,height:640}]) {
   const root=await contextFor(credentials.developer,viewport,mode==='preview');
   try {
    const response=await root.page.goto(address+'/admin/plugins/discourse-academy-roles/moderator-permissions',{waitUntil:'domcontentloaded',timeout:120000});
    assert.equal(response.status(),200);
    await root.page.locator('.academy-moderator-permissions .d-toggle-switch__checkbox-slider').first().waitFor();
    assert.equal(await root.page.locator('.academy-moderator-permissions [role=switch]').count(),20);
    assert.equal(await root.page.locator('.academy-moderator-permissions [role=switch][aria-checked=true]').count(),0);
    const settings=await read(root.page,'/academy-roles/admin/moderator-permissions.json');
    assert.equal(settings.status,200);assert.equal(Object.keys(settings.body.settings).length,20);
    assert.ok(Object.values(settings.body.values).every(value=>value===false));
    assert.ok(!/\[(?:zh_CN|en)\.academy_roles/.test(await root.page.locator('.admin-config-page__main-area.academy-moderator-permissions').innerText()),'Permission labels missing');
    await root.page.screenshot({path:reportPath.replace('.json','-'+viewport.name+'-permissions.png'),fullPage:true});

    const moderator=await contextFor(credentials.moderator,viewport);
    try {
     await moderator.page.goto(address+'/isbf/workbench',{waitUntil:'domcontentloaded',timeout:120000});
     await moderator.page.locator('.isbf-v2-workbench__grid').waitFor();
     const session=await read(moderator.page,'/session/current.json');
     assert.equal(session.status,200);
     const user=session.body.current_user;
     assert.equal(user.admin,false);assert.equal(user.academy_moderator_role,true);
     assert.ok(Object.values(user.academy_moderator_permissions).every(value=>value===false));
     assert.equal(user.can_review,false);
     denied(await read(moderator.page,'/academy-roles/admin/moderator-permissions.json'));
     denied(await read(moderator.page,'/academy-roles/admin/student-invites.json'));
     denied(await read(moderator.page,'/review.json'));
     const userPath='/admin/users/'+credentials.member.id+'.json';
     denied(await read(moderator.page,userPath));
     const site=await read(moderator.page,'/site.json');
     assert.equal(site.status,200);
     assert.ok(!site.body.categories.some(category=>category.id===3),'Internal board leaked with switches disabled');
     if(mode==='preview') {
      for(const permission of ['user_admin','review']) {
       await root.page.locator('[data-name="'+settings.body.settings[permission]+'"] .d-toggle-switch__label').click();
      }
      await root.page.locator('.academy-moderator-permissions [type=submit]').click();
      await root.page.locator('.form-kit__alert.alert-success').waitFor();
      assert.equal((await read(moderator.page,userPath)).status,200);
      assert.equal((await read(moderator.page,'/review.json')).status,200);
      for(const permission of ['user_admin','review']) {
       await root.page.locator('[data-name="'+settings.body.settings[permission]+'"] .d-toggle-switch__label').click();
      }
      await root.page.locator('.academy-moderator-permissions [type=submit]').click();
      await root.page.locator('.form-kit__alert.alert-success').waitFor();
      denied(await read(moderator.page,userPath));
      denied(await read(moderator.page,'/review.json'));
      const revoked=await read(root.page,'/academy-roles/admin/moderator-permissions.json');
      assert.ok(Object.values(revoked.body.values).every(value=>value===false));
     }
     assert.deepEqual(moderator.errors,[]);assert.deepEqual(moderator.brokenAssets,[]);
    } finally {await moderator.context.close();}
    assert.deepEqual(root.errors,[]);assert.deepEqual(root.brokenAssets,[]);
    report.actors.push({viewport:viewport.name,developer_only_configuration:true,twenty_switches_disabled:true,moderator_defaults_denied:true,same_session_revocation:mode==='preview'});
   } finally {await root.context.close();}

   const member=await contextFor(credentials.member,viewport);
   try {
    const sitePage=await member.page.goto(address+'/isbf/workbench',{waitUntil:'domcontentloaded',timeout:120000});
    assert.equal(sitePage.status(),200);await member.page.locator('.isbf-v2-workbench__grid').waitFor();
    await member.page.screenshot({path:reportPath.replace('.json','-'+viewport.name+'-workbench.png'),fullPage:true});
    report.workbench_diagnostics=await member.page.locator('.isbf-v2-workbench__card').evaluateAll(nodes=>nodes.map(node=>({href:node.getAttribute('href'),text:node.textContent,visible:node.getBoundingClientRect().width>0})));
    const siteMetadata=await read(member.page,'/site.json');
    report.workbench_configuration={marketplace:siteMetadata.body.isbf_marketplace,alumni_enabled:siteMetadata.body.isbf_alumni?.enabled};
    for(const href of ['/isbf/marketplace','/isbf/alumni']) assert.ok(await member.page.locator('.isbf-v2-workbench__card[href="'+href+'"]').isVisible(),'Workbench link missing: '+href);
    const products=member.page.waitForResponse(response=>new URL(response.url()).pathname==='/filter.json');
    await member.page.locator('.isbf-v2-workbench__card[href="/isbf/marketplace"]').click();
    const productsResponse=await products;assert.equal(productsResponse.status(),200);
    const productsBody=await productsResponse.json();const count=productsBody.topic_list.topics.length;
    await member.page.waitForFunction(count=>document.querySelectorAll('.isbf-marketplace-card').length===count && !document.querySelector('.isbf-marketplace__loading'),count);
    assert.equal(await member.page.locator('.isbf-marketplace [role=alert]').count(),0);
    await member.page.screenshot({path:reportPath.replace('.json','-'+viewport.name+'-marketplace.png'),fullPage:true});
    await member.page.goto(address+'/isbf/workbench',{waitUntil:'domcontentloaded',timeout:120000});
    await member.page.locator('.isbf-v2-workbench__card[href="/isbf/alumni"]').click();
    await member.page.locator('.isbf-alumni-map__canvas.leaflet-container').waitFor();
    await member.page.screenshot({path:reportPath.replace('.json','-'+viewport.name+'-alumni.png'),fullPage:true});
    assert.deepEqual(member.errors,[]);assert.deepEqual(member.brokenAssets,[]);
    report.viewports.push({viewport:viewport.name,workbench_links_visible:true,marketplace_products_loaded:count,alumni_map_initialized:true,javascript_errors:[],broken_assets:[]});
   } finally {await member.context.close();}
   console.log(mode+' '+viewport.name+' permissions, revocation and existing features passed');
  }
  report.passed=true;
 } catch(error) {
  report.failure={name:error.name,message:error.message,stack:error.stack};throw error;
 } finally {
  fs.writeFileSync(reportPath,JSON.stringify(report,null,2)+'\n');
  const path=require('node:path'),directory=path.dirname(reportPath),prefix=path.basename(reportPath,'.json')+'-';
  for(const name of [path.basename(reportPath),...fs.readdirSync(directory).filter(name=>name.startsWith(prefix)&&name.endsWith('.png'))]) {
   const file=path.join(directory,name);fs.chownSync(file,Number(ownerUid),Number(ownerGid));fs.chmodSync(file,0o600);
  }
  await browser.close();
 }
})().catch(error=>{console.error(error.stack);process.exitCode=1;});
"""


def verify(mode):
    assert mode in ["preview", "production"]
    application = "isbf_app" if mode == "production" else TEST_CONTAINER
    description = "ISBF admin permissions verification 20261011 " + mode
    ruby = """
require "json"
description=DESCRIPTION
raise "Verification sessions already exist" if UserAuthToken.where("user_agent LIKE ?", description + " %").exists?
developer=User.where(admin:true,active:true).where("id>0").order(:id).first!
moderator=User.where(admin:false,moderator:true,active:true,approved:true).where("id>0").order(:id).find{|user| !user.suspended? && !user.silenced?}
member=User.where(admin:false,moderator:false,active:true,approved:true,staged:false).where("id>0").order(:id).find{|user| !IsbfAnonymous.pool_user?(user) && !user.anonymous? && !user.suspended? && !user.silenced? && user.guardian.can_see_category?(Category.find(8))}
raise "Verification actors unavailable" unless moderator && member
result={}
UserAuthToken.transaction do
 {developer:developer,moderator:moderator,member:member}.each do |role,user|
  token=UserAuthToken.generate!(user_id:user.id,user_agent:description+" "+role.to_s,client_ip:"127.0.0.1")
  env=Rails.application.env_config.merge(Rack::MockRequest.env_for(MODE=="production" ? "https://isbf-one.com/" : "http://127.0.0.1:3411/"))
  jar=ActionDispatch::Request.new(env).cookie_jar
  Auth::DefaultCurrentUserProvider.new(env).set_auth_cookie!(token.unhashed_auth_token,user,jar)
  cookie_name=Auth::DefaultCurrentUserProvider::TOKEN_COOKIE
  cookie=CGI.escape(jar[cookie_name])
  check_env=env.merge("HTTP_COOKIE"=>cookie_name+"="+cookie)
  raise "Verification cookie unavailable" unless CurrentUser.lookup_from_env(check_env)&.id==user.id
  result[role]={id:user.id,cookie:cookie,cookie_name:cookie_name,token_id:token.id}
 end
end
puts JSON.generate(result)
""".replace("DESCRIPTION", repr(description)).replace("MODE", repr(mode))
    command = DOCKER + ["exec", "-u", "discourse" if mode == "production" else "root", "-w", "/var/www/discourse" if mode == "production" else "/src", "-e", "RAILS_ENV=production" if mode == "production" else "RAILS_ENV=development"]
    if mode == "preview":
        command += ["-e", "ISBF_PERMISSIONS_DATABASE=discourse_admin_permissions_preview_20261011", "-e", "DISCOURSE_REDIS_DB=8"]
    command += [application, "bin/rails", "runner"]
    credentials = None
    credential_file = ART / (mode + "-browser-credentials.json")
    report_file = ART / (mode + "-browser-report.json")
    try:
        credentials = json.loads(output(command + [ruby]))
        with credential_file.open("w") as handle:
            os.fchmod(handle.fileno(), 0o600)
            json.dump(credentials, handle)
        production_ip = output(DOCKER + ["inspect", "isbf_app", "--format", "{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}} "]) if mode == "production" else "127.0.0.1"
        address = "https://isbf-one.com" if mode == "production" else "http://127.0.0.1:3411"
        subprocess.run(DOCKER + ["exec", "-u", "root", "-i", "-w", "/src", "-e", "LD_LIBRARY_PATH=/task-tools/browser-libs", TEST_CONTAINER, "node", "-", mode, address, str(credential_file).replace(str(ART.parents[1]), "/src"), str(report_file).replace(str(ART.parents[1]), "/src"), production_ip, str(os.getuid()), str(os.getgid())], input=BROWSER, text=True, check=True)
    finally:
        credential_file.unlink(missing_ok=True)
        if credentials:
            token_ids = [item["token_id"] for item in credentials.values()]
            token_owners = {item["token_id"]: item["id"] for item in credentials.values()}
            cleanup = "owners=OWNERS; UserAuthToken.where(id: IDS).find_each { |token| raise \"Verification token owner changed\" unless token.user_id == owners.fetch(token.id); raise \"Verification token provenance unavailable\" unless UserAuthTokenLog.where(user_auth_token_id: token.id, action: \"generate\").where(\"user_agent LIKE ?\", DESCRIPTION + \" %\").exists?; token.destroy! }; raise \"Verification session cleanup failed\" if UserAuthToken.where(id: IDS).exists?; puts \"Temporary verification sessions removed\"".replace("OWNERS", str(token_owners).replace(":", " =>")).replace("IDS", repr(token_ids)).replace("DESCRIPTION", repr(description))
            print(output(command + [cleanup]), flush=True)
            if report_file.exists():
                report = json.loads(report_file.read_text())
                report["verification_sessions_removed"] = True
                save_json(report_file, report)


if __name__ == "__main__":
    verify(sys.argv[1])
