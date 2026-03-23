import os
import re
import json

swift_dir = 'Randomitas'

for root, dirs, files in os.walk(swift_dir):
    for file in files:
        if file.endswith('.swift'):
            path = os.path.join(root, file)
            with open(path, 'r', encoding='utf-8') as f:
                content = f.read()

            new_content = content
            
            # fix plurals
            # 1. "\(foldersToMove.count) elemento\(foldersToMove.count > 1 ? "s" : "")" -> "^[\(foldersToMove.count) elemento](inflect: true)"
            new_content = re.sub(
                r'\"\\\\\(([^)]+\.count)\)\s+elemento\\\\\(.*?\"\)\"',
                r'"^[\(\g<1>) elemento](inflect: true)"',
                new_content
            )
            
            # 2. "\(createdCount) elemento\(createdCount > 1 ? "s" : "") creado\(createdCount > 1 ? "s" : "")"
            new_content = re.sub(
                r'\"\\\\\([^)]+\s+elemento\\\\\(.+?creado\\\\\(.*?\"\)\"',
                r'"^[\(createdCount) elemento creado](inflect: true)"',
                new_content
            )

            # fix integer interpolations Text("\(someInt)") to Text(verbatim: "\(someInt)")
            # Look for exactly Text("\(identifier)")
            new_content = re.sub(
                r'Text\(\"\\\\\(([a-zA-Z0-9_.]+)\)\"\)',
                r'Text(verbatim: "\(\g<1>)")',
                new_content
            )

            if content != new_content:
                with open(path, 'w', encoding='utf-8') as f:
                    f.write(new_content)
                print(f'Updated {path}')

xcstrings_path = 'Randomitas/Localizable.xcstrings'
with open(xcstrings_path, 'r', encoding='utf-8') as f:
    data = json.load(f)

# delete the leftover keys
to_delete = ['%lld elemento%@', '%lld elemento%@ creado%@']
for key in to_delete:
    if key in data.get('strings', {}):
        del data['strings'][key]
        print(f'Deleted key {key}')

with open(xcstrings_path, 'w', encoding='utf-8') as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
