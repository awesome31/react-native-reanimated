#!/bin/bash
set -e
set -x

ROOT=$(pwd)

unset CI

# versions=("0.65.1" "0.64.1" "0.63.3" "0.62.2 --dev")
versions=("0.65.1" "0.64.2")
rnv8_versions=("0.65.1-patch.1" "0.64.2-patch.1")
version_name=("65" "64")

# for index in {0..3}
for index in {0..1}
do
  yarn add react-native@"${versions[$index]}"
  for js_runtime in "hermes" "jsc" "v8"
  do
    echo "js_runtime=${js_runtime}"

    if [ "${js_runtime}" == "v8" ]; then
      yarn add react-native-v8@"${rnv8_versions[$index]}"
    fi

    cd android 
    gradle clean

    JS_RUNTIME=${js_runtime} gradle :assembleDebug
    cd $ROOT

    rm -rf android-npm/react-native-reanimated-"${version_name[$index]}-${js_runtime}".aar
    cp android/build/outputs/aar/*.aar android-npm/react-native-reanimated-"${version_name[$index]}-${js_runtime}".aar

    if [ "${js_runtime}" == "v8" ]; then
      yarn remove react-native-v8
    fi
  done
done

rm -rf libSo
mkdir libSo
cd libSo
mkdir fbjni
cd fbjni
wget https://repo1.maven.org/maven2/com/facebook/fbjni/fbjni/0.2.2/fbjni-0.2.2.aar
unzip fbjni-0.2.2.aar 
rm -r $(find . ! -name '.' ! -name 'jni' -maxdepth 1)
rm $(find . -name '*libc++_shared.so')
cd ../..

yarn add react-native@0.64.1 --dev

mv android android-temp
mv android-npm android

yarn run type:generate

npm pack

mv android android-npm
mv android-temp android

rm -rf ./lib
rm -rf ./libSo

echo "Done!"
