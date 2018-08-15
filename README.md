# eos-tester
Tool for quick start/stop eos contract dev environment & write test

# Installation
## Requirements
 - docker > ~v17
 - node > ~v8
 
 ## installation
 ```
  git clone https://github.com/mixbytes/eos-tester
  cd eos-tester
  sudo ./install.sh
 ```
  
# Usage
```
 $ eos-tester help
Usage:
                 init       initalize eos-dev
                 compile    compile contracts
                 test       test commands
                 clear      clear all data
                 node       start, stop custom node
```

# Commands
  - init  - initialize environment in current directory
  - compile - compile contracts
  - node <start|stop> - start/stop development eos node
  - test - run all tests
  - clear - clear all logs & blocks
  
