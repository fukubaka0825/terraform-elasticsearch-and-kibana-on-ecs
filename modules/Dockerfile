FROM docker.elastic.co/elasticsearch/elasticsearch:7.4.0
#### 形態素解析のプラグイン等インストールする場合はここに列挙する
RUN \
elasticsearch-plugin install --batch analysis-icu && \
elasticsearch-plugin install --batch analysis-kuromoji
ENV REGION ap-northeast-1
ADD elasticsearch.yml /usr/share/elasticsearch/config/
USER root
RUN chown elasticsearch:elasticsearch config/elasticsearch.yml
USER elasticsearch
WORKDIR /usr/share/elasticsearch

