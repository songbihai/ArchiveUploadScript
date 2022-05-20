#使用方法

if [ ! -d ./IPADir ];
then
mkdir -p IPADir;
fi

#工程绝对路径
project_path=$(cd `dirname $0`; pwd)

#工程名 将XXX替换成自己的工程名
project_name=XXX

#scheme名 将XXX替换成自己的sheme名
scheme_name=XXX

#ipa名 将XXX替换成自己的ipa名(安装后手机显示的app的名字) 最后生成的XXX.ipa
ipa_name=XXX

#打包模式 Debug/Release
development_mode=Debug

#build文件夹路径
build_path=${project_path}/build

#plist文件所在路径
exportOptionsPlistPath=${project_path}/exportTest.plist

#导出.ipa文件所在路径
exportIpaPre=${project_path}/IPADir
ipaNum=`ls -l $exportIpaPre |grep "^d"|wc -l`
ipaNum=${ipaNum// /}
echo +++++++++++$ipaNum
exportIpaPath=${project_path}/IPADir/${development_mode}
if [ $ipaNum -ge 0 ];then
exportIpaPath=${project_path}/IPADir/${development_mode}_${ipaNum}
fi

#archive名字
archiveNum=`ls -l $build_path |grep "^d"|wc -l`
archiveNum=${archiveNum// /}
archiveName=${project_name}.xcarchive
if [ $archiveNum -ge 0 ];then
archiveName=${project_name}_${archiveNum}.xcarchive
fi


echo "Place enter the number you want to export ? [ 1:app-store 2:ad-hoc] "

##
read number
while([[ $number != 1 ]] && [[ $number != 2 ]])
do
echo "Error! Should enter 1 or 2"
echo "Place enter the number you want to export ? [ 1:app-store 2:ad-hoc] "
read number
done

if [ $number == 1 ];then
development_mode=Release
exportOptionsPlistPath=${project_path}/exportAppstore.plist
else
development_mode=Debug
exportOptionsPlistPath=${project_path}/exportTest.plist
fi


echo '///-----------'
echo '/// 正在清理工程'
echo '///-----------'
xcodebuild \
clean \
-workspace ${project_path}/${project_name}.xcworkspace \
-scheme ${scheme_name} \
-configuration ${development_mode} \
-destination 'generic/platform=iOS' \
-quiet  || exit


echo '///--------'
echo '/// 清理完成'
echo '///--------'
echo ''

echo '///-----------'
echo '/// 正在编译工程:'${development_mode}
echo '///-----------'
xcodebuild \
archive -workspace ${project_path}/${project_name}.xcworkspace \
-scheme ${scheme_name} \
-configuration ${development_mode} \
-archivePath ${build_path}/${archiveName} \
-destination 'generic/platform=iOS' \
-quiet  || exit

echo '///--------'
echo '/// 编译完成'
echo '///--------'
echo ''

echo '///----------'
echo '/// 开始ipa打包'
echo '///----------'
xcodebuild -exportArchive -archivePath ${build_path}/${archiveName} \
-configuration ${development_mode} \
-exportPath ${exportIpaPath} \
-exportOptionsPlist ${exportOptionsPlistPath} \
-destination 'generic/platform=iOS'\
-quiet || exit

if [ -e $exportIpaPath/$ipa_name.ipa ]; then
echo '///----------'
echo '/// ipa包已导出'
echo '///----------'
open $exportIpaPath
else
echo '///-------------'
echo '/// ipa包导出失败 '
echo '///-------------'
fi
echo '///------------'
echo '/// 打包ipa完成  '
echo '///-----------='
echo ''

echo '///-------------'
echo '/// 开始发布ipa包 '
echo '///-------------'

IPA_PATH=$exportIpaPath/$ipa_name.ipa

if [ $number == 1 ];then

#验证并上传到App Store
#你需要准备apiKey & apiIssuer
#登陆itunes connection,
#点击用户和访问 > 密钥 > 生成密钥 (帐户的拥有人,才有权限生成)
#生成后可以找到 密钥ID(apiKey) & IssuerId (apiIssuer)
#也把密钥下载下来, 在mac上: 你的用户目录新建一个private_keys文件夹把秘钥放进去，否则会报错。

#将XXX替换成自己的apiKey
apiKey=XXX
#将XXX替换成自己的apiIssuer
apiIssuer=XXX
#验证
xcrun altool --validate-app -f ${exportIpaPath}/${scheme_name}.ipa -t iOS --apiKey $apiKey --apiIssuer $apiIssuer --verbose
#上传
xcrun altool --upload-app -f ${exportIpaPath}/${scheme_name}.ipa -t iOS --apiKey $apiKey --apiIssuer $apiIssuer --verbose

else

#上传到蒲公英
#将的XXX替换成自己的蒲公英账号下的appKey
appKey="XXX"

echo '///------正在上传:'${IPA_PATH}
 
curl https://www.pgyer.com/apiv2/app/upload -F "file=@${IPA_PATH}" -F "_api_key=${appKey}" --header "enctype: multipart/form-data"

fi

exit 0


