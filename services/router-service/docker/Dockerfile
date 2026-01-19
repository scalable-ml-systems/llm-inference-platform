FROM python:3.11-slim

WORKDIR /app
COPY services/router-service/requirements.txt /app/requirements.txt
RUN pip install --no-cache-dir -r /app/requirements.txt

COPY services/router-service/src /app/src
# Configs mounted via ConfigMap in K8s; for local you can copy if you want
EXPOSE 8080

ENV PYTHONPATH=/app/src
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8080"]
