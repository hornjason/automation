
  3 # $1 is the variable name
  4 # $2 is the thing to replace it with.
  5 function checkOrDefault() {
  6     if [[ -z ${!1+x} ]]; then
  7         if [[ -z ${2+x} ]]; then
  8             echo "Must provide $1 in environment" 1>&2
  9             exit 1
 10         else
 11             export $1=$2
 12         fi
 13     fi
 14 }
 15
 16 checkOrDefault "DOCKER_REGISTRY_URL"
 17 checkOrDefault "VERSION"
 18 checkOrDefault "PROJECT"
 19 checkOrDefault "APP_NAME"
 20
 21 checkOrDefault "DOCKER_REGISTRY_USERNAME" "$(oc whoami)"
 22 checkOrDefault "DOCKER_REGISTRY_PASSWORD" "$(oc whoami -t)"
 23
 24 TAG="$DOCKER_REGISTRY_URL/$PROJECT/$APP_NAME:$VERSION"
 25
 26 # THIS IS THE TASK THAT WOULD BE PERFORMED BY BAMBOO
 27 function BUILD() {
 28     echo docker login -u $DOCKER_REGISTRY_USERNAME -p $DOCKER_REGISTRY_PASSWORD $DOCKER_REGISTRY_URL
 29     echo docker build -t $TAG .
 30     echo docker push $TAG
 31 }
 32
 33 # THIS IS THE TASK THAT WOULD BE PERFORMED BY OCTOPUS
 34 function MOVE() {
 35     checkOrDefault "SOURCE_DOCKER_REGISTRY"
 36     checkOrDefault "SOURCE_DOCKER_REGISTRY_USERNAME" "$(oc whoami)"
 37     checkOrDefault "SOURCE_DOCKER_REGISTRY_PASSWORD" "$(oc whoami -t)"
 38
 39     SOURCE_TAG="$DOCKER_REGISTRY_URL/$PROJECT/$APP_NAME:$VERSION"
 40
 41     echo docker login -u $SOURCE_DOCKER_REGISTRY_USERNAME -p $SOURCE_DOCKER_REGISTRY_PASSWORD $SOURCE_DOCKER_REGISTRY
 42     echo docker pull $SOURCE_TAG
 43
 44     echo docker tag $SOURCE_TAG $TAG
 45
 46     echo docker login -u $DOCKER_REGISTRY_USERNAME -p $DOCKER_REGISTRY_PASSWORD $DOCKER_REGISTRY_URL
 47     echo docker push $TAG
 48 }
 49
 50 if [[ $1 == "MOVE" ]]; then
 51     MOVE
 52 elif [[ $1 == "BUILD" ]]; then
 53     BUILD
 54 else
 55     echo "Must provide a command to run: BUILD or MOVE" 1>&2
 56     exit 1
 57 fi
