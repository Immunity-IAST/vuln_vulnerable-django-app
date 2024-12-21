FROM python:3.10 AS base

WORKDIR /app

COPY requirements.txt /app/.

RUN pip install -r requirements.txt

COPY vda /app

FROM base AS run

EXPOSE 8000

CMD [ "python3", "manage.py", "runserver", "0.0.0.0:8000" ]

FROM base AS iast

EXPOSE 8000

ARG IMMUNITY_HOST

ARG IMMUNITY_PORT

ARG IMMUNITY_PROJECT

ENV INSTRUMENTED=True

RUN pip install requests immunity-iast==0.2.8 --upgrade

RUN python3 -m immunity_agent $IMMUNITY_HOST $IMMUNITY_PORT $IMMUNITY_PROJECT

CMD [ "python3", "manage.py", "runserver", "0.0.0.0:8000" ]
