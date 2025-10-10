cd ~/Apps/datagouv/udata-front-kit/

echo "Push simplifions-preprod branch"
git co main
git pull origin main
git branch -D simplifions-preprod
git co -b simplifions-preprod
git push origin simplifions-preprod -f

echo "Deploy simplifions-prod branch"
git branch -D simplifions-prod
git fetch
git co simplifions-prod
git merge simplifions-preprod
git push origin simplifions-prod

echo "Now go to https://github.com/opendatateam/udata-front-kit/actions/workflows/create-deploy-release.yml and trigger new deployments from simplifions-prod and simplifions-preprod"