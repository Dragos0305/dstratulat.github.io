# Fallback deployment for when GitHub Pages is unavailable.
# Builds the static site with Zensical, then serves it with nginx.

FROM python:3.13-slim AS build
WORKDIR /src
RUN pip install --no-cache-dir zensical
COPY zensical.toml ./
COPY docs ./docs
RUN zensical build --clean

FROM nginx:1.27-alpine
COPY --from=build /src/site /usr/share/nginx/html
COPY docker/nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
