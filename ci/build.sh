#!/bin/sh

echo "Starting build process in: `pwd`"
set -e

VERSION="${TRAVIS_TAG:-0.0.0}"
: "${DOCKER_TAG:=sumologic/fluentd-kubernetes-sumologic}"
: "${DOCKER_USERNAME:=sumodocker}"
PLUGIN_NAME="fluent-plugin-kubernetes_sumologic"

echo "Building for tag $VERSION, modify .gemspec file..."
sed -i.bak "s/0.0.0/$VERSION/g" ./$PLUGIN_NAME.gemspec
rm -f ./$PLUGIN_NAME.gemspec.bak

echo "Install bundler..."
bundle install

echo "Run unit tests..."
bundle exec rake

echo "Build gem $PLUGIN_NAME $VERSION..."
gem build $PLUGIN_NAME

echo "Building docker image with $DOCKER_TAG:$VERSION and $DOCKER_TAG:latest in `pwd`..."
docker build . -f ./Dockerfile -t $DOCKER_TAG:$VERSION # --no-cache
docker build . -f ./Dockerfile -t $DOCKER_TAG:latest

if [[ -z "${DOCKER_PASSWORD}" ]] || [[ -z "${TRAVIS_TAG}" ]]; then
    echo "Skip Docker pushing"
else
    echo "Pushing docker image with $DOCKER_TAG:$VERSION and $DOCKER_TAG:latest..."
    echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin
    docker push $DOCKER_TAG:$VERSION
    docker push $DOCKER_TAG:latest
fi

rm -f ./*.gem

echo "DONE"
