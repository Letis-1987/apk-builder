FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# 1. Установка базовых системных зависимостей, CMake, Ninja, JDK 17 и libxkbcommon0 (критично для инструментов Qt 6)
RUN apt-get update && apt-get install -y --no-install-recommends \
    apt-utils \
    git \
    wget \
    unzip \
    curl \
    p7zip-full \
    python3 \
    python3-pip \
    python3-setuptools \
    build-essential \
    cmake \
    ninja-build \
    openjdk-17-jdk \
    libgl1-mesa-dev \
    libxkbcommon0 \
    && rm -rf /var/lib/apt/lists/*

# Настройка Java окружения
ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
ENV PATH=$JAVA_HOME/bin:$PATH

# 2. Установка Android SDK & NDK
ENV ANDROID_HOME=/opt/android-sdk
ENV ANDROID_SDK_ROOT=/opt/android-sdk
ARG SDK_TOOLS_VERSION=11076708 
ARG NDK_VERSION=26.1.10909125 

RUN mkdir -p ${ANDROID_HOME}/cmdline-tools && \
    wget -q https://dl.google.com/android/repository/commandlinetools-linux-${SDK_TOOLS_VERSION}_latest.zip -O /tmp/cmdline-tools.zip && \
    unzip -q /tmp/cmdline-tools.zip -d ${ANDROID_HOME}/cmdline-tools && \
    mv ${ANDROID_HOME}/cmdline-tools/cmdline-tools ${ANDROID_HOME}/cmdline-tools/latest && \
    rm /tmp/cmdline-tools.zip

ENV PATH=${ANDROID_HOME}/cmdline-tools/latest/bin:${ANDROID_HOME}/platform-tools:$PATH

# Принятие лицензий и установка необходимых компонентов SDK/NDK
RUN yes | sdkmanager --licenses && \
    sdkmanager --update && \
    sdkmanager "platforms;android-35" \
               "build-tools;35.0.0" \
               "platform-tools" \
               "ndk;${NDK_VERSION}"

ENV ANDROID_NDK_ROOT=${ANDROID_HOME}/ndk/${NDK_VERSION}

# 3. Установка Qt 6 для Android и хостовых инструментов через aqtinstall
ARG QT_VERSION=6.8.0
ENV QT_PATH=/opt/qt

# Флаг --no-modules для desktop обязателен: он скачает только утилиты (moc, rcc), сэкономив гигабайты и память в CI
RUN pip3 install --break-system-packages aqtinstall && \
    AQT_MAX_WORKERS=1 aqt install-qt linux desktop ${QT_VERSION} gcc_64 --base --outputdir ${QT_PATH} && \
    AQT_MAX_WORKERS=1 aqt install-qt linux android ${QT_VERSION} android_arm64_v8a --outputdir ${QT_PATH}

# Прописываем пути к Qt внутри образа
ENV QT_ANDROID_DIR=${QT_PATH}/${QT_VERSION}/android_arm64_v8a
ENV PATH=${QT_PATH}/${QT_VERSION}/android_arm64_v8a/bin:$PATH

WORKDIR /workspace

CMD ["/bin/bash"]
