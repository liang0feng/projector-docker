#!/bin/bash

#
# Copyright 2019-2020 JetBrains s.r.o.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# search for IDE runner sh file:

THIS_FILE_NAME=$(basename "$0")

ideRunnerCandidates=($(grep -lr --include=*.sh "com.intellij.idea.Main\|jetbrains.mps.Launcher" .))

# remove this file from candidates:
for i in "${!ideRunnerCandidates[@]}"; do
    if [[ ${ideRunnerCandidates[i]} = *$THIS_FILE_NAME* ]]; then
        unset 'ideRunnerCandidates[i]'
    elif [[ ${ideRunnerCandidates[i]} = *"projector"* ]]; then
        unset 'ideRunnerCandidates[i]'
    elif [[ ${ideRunnerCandidates[i]} = *"game-tools.sh" ]]; then
        unset 'ideRunnerCandidates[i]'
    fi
done

if [[ ${#ideRunnerCandidates[@]} != 1 ]]; then
    echo "Can't find a single candidate to be IDE runner script so can't select a single one:"
    echo ${ideRunnerCandidates[*]}
    exit 1
fi

ideRunnerCandidate=${ideRunnerCandidates[@]}
ideRunnerWithoutPrefix=${ideRunnerCandidate/"./"/""}
IDE_RUN_FILE_NAME=${ideRunnerWithoutPrefix/".sh"/""}
echo "Found IDE: $IDE_RUN_FILE_NAME"

cp "$IDE_RUN_FILE_NAME.sh" "$IDE_RUN_FILE_NAME-projector.sh"

# change
# classpath "$CLASSPATH"
# to
# classpath "$CLASSPATH:$IDE_HOME/projector-server/lib/*"
sed -i 's+classpath "$CLASSPATH"+classpath "$CLASSPATH:$IDE_HOME/projector-server/lib/*"+g' "$IDE_RUN_FILE_NAME-projector.sh"

# change
# com.intellij.idea.Main
# to
# -Dorg.jetbrains.projector.server.classToLaunch=com.intellij.idea.Main org.jetbrains.projector.server.ProjectorLauncher
sed -i 's+com.intellij.idea.Main+-Dorg.jetbrains.projector.server.classToLaunch=com.intellij.idea.Main org.jetbrains.projector.server.ProjectorLauncher+g' "$IDE_RUN_FILE_NAME-projector.sh"

# change
# ${MAIN_CLASS}
# to
# -Dorg.jetbrains.projector.server.classToLaunch=${MAIN_CLASS} org.jetbrains.projector.server.ProjectorLauncher
sed -i 's+\${MAIN_CLASS}+-Dorg.jetbrains.projector.server.classToLaunch=\${MAIN_CLASS} org.jetbrains.projector.server.ProjectorLauncher+g' "$IDE_RUN_FILE_NAME-projector.sh"

# leif #### 判断目录/home/kingdee，不为空，就将/projector/projector-user/* 复制到/home/kingdee目录下
# 指定要检查的目录
DIR_TO_CHECK="/home/kingdee"

# 检查目录是否存在且不为空
if [ -d "$DIR_TO_CHECK" ] && [ "$(ls -A "$DIR_TO_CHECK")" ]; then
    # 目录不为空，执行复制操作
    # 源目录
    SRC_DIR="/projector/projector-user"
    # 目标目录
    DEST_DIR="$DIR_TO_CHECK"

    # 复制所有文件和目录到目标目录
    cp -r "$SRC_DIR"/* "$DEST_DIR"/
    echo "Copied contents from $SRC_DIR to $DEST_DIR."
else
    # 目录为空或不存在，不执行操作
    echo "Directory $DIR_TO_CHECK is empty or does not exist."
fi

bash "$IDE_RUN_FILE_NAME-projector.sh"

rm "$IDE_RUN_FILE_NAME-projector.sh"
