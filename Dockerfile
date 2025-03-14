FROM alpine:latest AS builder

RUN apk add --no-cache \
    openjdk8 \
    cmake \
    make \
    g++ \
    gcc \
    linux-headers \
    proj-dev \
    gdal-dev \
    git \
    curl \
    swig \
    unzip \
    bash \
    maven \
    apache-ant

ENV JAVA_HOME=/usr/lib/jvm/java-1.8-openjdk
ENV LD_LIBRARY_PATH=/lib:/usr/lib:/usr/local/lib

# Install GDAL
ENV INSTALL_PREFIX=/usr/local
ARG GDAL_VERSION=3.6.2

RUN mkdir -p /opt/gdal \
 && cd /opt/gdal \
 && curl -LOs https://download.osgeo.org/gdal/${GDAL_VERSION}/gdal-${GDAL_VERSION}.tar.gz \
 && tar xzf gdal-${GDAL_VERSION}.tar.gz \
 && mkdir build \
 && cd build \
 && cmake \
      -DBUILD_JAVA_BINDINGS:BOOL=ON \
      -DJAVA_HOME:PATH=$JAVA_HOME \
      -DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX} \
      -DCMAKE_PREFIX_PATH:PATH=${INSTALL_PREFIX} \
      -DBUILD_SHARED_LIBS:BOOL=ON \
      -DCMAKE_BUILD_TYPE=Release \
      ../gdal-${GDAL_VERSION} \
 && make -j$(nproc) \
 && make install \
 && cd / \
 && rm -rf /opt/gdal

RUN mvn install:install-file \
      -Dfile=/usr/local/share/java/gdal-${GDAL_VERSION}.jar \
      -DgroupId=org.gdal \
      -DartifactId=gdal \
      -Dversion=${GDAL_VERSION} \
      -Dpackaging=jar \
      -DgeneratePom=true

# Make a symlink in /usr/local/lib so we don't need LD_LIBRARY_PATH to load it
# dynamically from Java
RUN ln -sf /usr/local/share/java/libgdalalljni.so /usr/local/lib

# Update ld.so configuration
RUN ldconfig /etc/ld.so.conf.d

# Install RUGGED as it is a fork for now
RUN mkdir -p /opt/rugged \
 && cd /opt/rugged \
 && curl -Lo rugged-4.0.1.jar \
      https://gitlab.eopf.copernicus.eu/geolib/sxgeo/-/raw/main/jar/rugged-4.0.1.jar \
 && mvn install:install-file \
      -Dfile=rugged-4.0.1.jar \
      -DgroupId=org.orekit \
      -DartifactId=rugged \
      -Dversion=4.0.1 \
      -Dpackaging=jar \
      -DgeneratePom=true \
 && cd / \
 && rm -rf /opt/rugged


WORKDIR /Sen2vm

CMD ["sh"]
