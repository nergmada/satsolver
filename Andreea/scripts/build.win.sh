printf '\033[0;32m --[[ Cleaning existing directory ]]-- \033[0m\n'
rm -rf ./build/
printf 'building scripts'
echo 'moonc -t ./build ./src' | cmd
printf 'unfurling the src folder'
mv ./build/src/* ./build
rm -rf ./build/src
cp ./src/utils/*.lua ./build/utils
mkdir ./build/tests
cp ./tests/* ./build/tests
