# Copyright (c) 2022 LG Electronics Inc.
# SPDX-License-Identifier: Apache-2.0
FROM python:3.8-slim-buster

COPY . /app
WORKDIR /app

# Install necessary packages including nodejs, npm, and default-jdk
RUN ln -sf /bin/bash /bin/sh && \
  apt-get update && \
  apt-get install --no-install-recommends -y \
  build-essential \
  python3 python3-distutils python3-pip python3-dev python3-magic \
  libxml2-dev \
  libxslt1-dev \
  libhdf5-dev \
  bzip2 xz-utils zlib1g libpopt0 \
  curl \
  default-jdk \
  gradle \
  wget \
  unzip \
  ruby-full \
  golang-go \
  && \
  curl -sL https://deb.nodesource.com/setup_14.x | bash - && \
  apt-get install -y nodejs && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/*

# Set JAVA_HOME dynamically
RUN echo "export JAVA_HOME=\$(dirname \$(dirname \$(readlink -f \$(which java))))" >> /etc/profile && \
    echo "export PATH=\$JAVA_HOME/bin:\$PATH" >> /etc/profile

# Install license-checker globally
RUN npm install -g license-checker

# Install Android SDK
RUN mkdir -p /opt/android-sdk && \
    wget -q https://dl.google.com/android/repository/commandlinetools-linux-7583922_latest.zip && \
    unzip -q commandlinetools-linux-7583922_latest.zip -d /opt/android-sdk && \
    rm commandlinetools-linux-7583922_latest.zip && \
    yes | /opt/android-sdk/cmdline-tools/bin/sdkmanager --licenses && \
    /opt/android-sdk/cmdline-tools/bin/sdkmanager "platform-tools" "build-tools;30.0.3"

# Install Flutter
RUN git clone https://github.com/flutter/flutter.git /opt/flutter && \
    /opt/flutter/bin/flutter precache

# Install CocoaPods
RUN gem install cocoapods

# Install Carthage
RUN brew install carthage

# Install .NET Core SDK
RUN wget https://packages.microsoft.com/config/debian/10/packages-microsoft-prod.deb -O packages-microsoft-prod.deb && \
    dpkg -i packages-microsoft-prod.deb && \
    apt-get update && \
    apt-get install -y apt-transport-https && \
    apt-get update && \
    apt-get install -y dotnet-sdk-3.1

# Install Helm
RUN curl https://baltocdn.com/helm/signing.asc | apt-key add - && \
    echo "deb https://baltocdn.com/helm/stable/debian/ all main" | tee /etc/apt/sources.list.d/helm-stable-debian.list && \
    apt-get update && \
    apt-get install helm

# Rest of the Dockerfile remains the same...

RUN pip3 install --upgrade pip && \  
    pip3 install fosslight_util && \  
    pip3 install python-magic && \  
    pip3 install dparse  

RUN pip3 install fosslight_source --no-deps && \  
    pip3 show fosslight_source | grep "Requires:" | sed 's/Requires://' | tr ',' '\n' | grep -v "typecode-libmagic" > /tmp/fosslight_source_deps.txt && \  
    pip3 install -r /tmp/fosslight_source_deps.txt && \  
    rm /tmp/fosslight_source_deps.txt

COPY requirements.txt /tmp/requirements.txt
RUN grep -vE "fosslight[-_]source" /tmp/requirements.txt > /tmp/custom_requirements.txt && \
    pip3 install -r /tmp/custom_requirements.txt && \
    rm /tmp/requirements.txt /tmp/custom_requirements.txt

COPY . /fosslight_scanner
WORKDIR /fosslight_scanner
RUN pip3 install . --no-deps && \
    rm -rf ~/.cache/pip /root/.cache/pip

# Add /usr/local/bin to the PATH
ENV PATH="/usr/local/bin:/opt/flutter/bin:${PATH}"
ENV ANDROID_HOME="/opt/android-sdk"

VOLUME /src
WORKDIR /src

# Create and set up the entrypoint script
RUN echo '#!/bin/bash' > /entrypoint.sh && \
    echo 'source /etc/profile' >> /entrypoint.sh && \
    echo 'export JAVA_HOME=$(dirname $(dirname $(readlink -f $(which java))))' >> /entrypoint.sh && \
    echo 'export PATH=$JAVA_HOME/bin:$PATH' >> /entrypoint.sh && \
    echo 'if command -v "$1" > /dev/null 2>&1; then' >> /entrypoint.sh && \
    echo '    exec "$@"' >> /entrypoint.sh && \
    echo 'else' >> /entrypoint.sh && \
    echo '    exec fosslight "$@"' >> /entrypoint.sh && \
    echo 'fi' >> /entrypoint.sh && \
    chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]

CMD ["-h"]

# Clean up the build
RUN apt-get clean && \
    rm -rf /var/lib/apt/lists/*