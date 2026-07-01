import zipfile
import os
import glob
home = os.path.expanduser('~')
root = os.path.join(home, '.gradle', 'caches', 'modules-2', 'files-2.1', 'org.jetbrains.kotlin', 'kotlin-gradle-plugin')
print('root:', root)
if not os.path.isdir(root):
    raise SystemExit('root not found')
for ver_dir in glob.glob(os.path.join(root, '*')):
    for jar in glob.glob(os.path.join(ver_dir, '**', '*.jar'), recursive=True):
        if '2.3.10' in jar:
            with zipfile.ZipFile(jar, 'r') as zf:
                names = [n for n in zf.namelist() if 'compilerOptions' in n or 'KotlinJvm' in n or 'kotlinOptions' in n or 'KotlinCompile' in n]
                if names:
                    print('JAR', jar)
                    for n in names:
                        print('  ', n)
            break
