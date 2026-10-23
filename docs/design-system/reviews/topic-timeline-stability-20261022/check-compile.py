import subprocess

subprocess.run(['ruby', '/review/compile-style.rb'], check=True)
subprocess.run(['node', '/review/compile-browser.cjs'], check=True)
