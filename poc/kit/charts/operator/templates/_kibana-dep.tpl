{{- define "operator.kibanaDeployment" }}
{{- if .elkIntegrationEnabled }}
---
apiVersion: apps/v1beta1
kind: Deployment
metadata:
  name: kibana
  labels:
    app: kibana
spec:
  replicas: 1
  selector:
    matchLabels:
      app: kibana
  template:
    metadata:
      labels:
        app: kibana
    spec:
      containers:
      - name: kibana
        image: kibana:5
        ports:
        - containerPort: 5601
{{- end }}
{{- end }}
