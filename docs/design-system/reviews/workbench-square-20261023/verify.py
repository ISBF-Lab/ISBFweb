import subprocess
for command in [['ruby','/review/compile-style.rb'],['node','/review/compile-browser.cjs'],['python3','/review/check-browser.py']]:
 subprocess.run(command,check=True)
