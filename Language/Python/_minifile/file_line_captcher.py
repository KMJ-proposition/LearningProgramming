import os
import re

path = "G:\\Steam\\steamapps\\common\\Palworld\\vortex.deployment.json"
output = []

if os.path.exists(path):
    with open(f"{path}", encoding="utf-8") as f:
        for line in f:
            match = re.search(r"mod(.*)", line.lower())
            if match:
                parts = (sorted(set(match.group(1).strip().split("\\"))))                
                output.append(parts)

    with open("G:\\Steam\\steamapps\\common\\Palworld\\output.txt", "w", encoding="utf-8") as f:
        for parts in output:
            f.write(",".join(parts) + "\n")
                         
else:
    print("파일 또는 경로가 존재하지 않습니다.")

    
