{{- define "operator.clusterRoleBinding" }}
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  labels:
    weblogic.operatorName: {{ .operatorNamespace }}
    weblogic.resourceVersion: operator-v1
  name: {{ .operatorNamespace }}-operator-rolebinding
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: weblogic-operator-cluster-role
subjects:
- kind: ServiceAccount
  name: {{ .operatorServiceAccount }}
  namespace: {{ .operatorNamespace }}
{{- end }}
