import subprocess
from pathlib import Path
subprocess.run(['python3','/review/run-lint.py'],check=True)
Path('/review/source/live-candidate/javascripts/discourse/components/isbf-v2-workbench.gjs').write_bytes(Path('/workspace/themes/isbf-campus-feed/javascripts/discourse/components/isbf-v2-workbench.gjs').read_bytes())
subprocess.run(['node','/review/compile-browser.cjs'],check=True)
subprocess.run(['python3','/review/check-browser.py'],check=True)
