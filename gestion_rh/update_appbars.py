import os
import re

directory = 'lib/screens'

pattern = re.compile(r"AppBar\(\s*title:\s*const\s*Text\((.*?)\)\s*\)")

def replace_appbar(match):
    text_content = match.group(1)
    return f"AppBar(title: Row(mainAxisSize: MainAxisSize.min, children: [ Image.asset('assets/images/stb_logo.png', height: 28), const SizedBox(width: 12), const Text({text_content}) ]))"

for root, dirs, files in os.walk(directory):
    for file in files:
        if file.endswith('.dart'):
            filepath = os.path.join(root, file)
            with open(filepath, 'r', encoding='utf-8') as f:
                content = f.read()
            
            new_content = pattern.sub(replace_appbar, content)
            
            if new_content != content:
                with open(filepath, 'w', encoding='utf-8') as f:
                    f.write(new_content)
                print(f'Updated {filepath}')
print('Done!')
