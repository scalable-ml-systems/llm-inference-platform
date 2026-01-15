{{- define "inference-backend.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "inference-backend.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := include "inference-backend.name" . -}}
{{- printf "%s-%s" $name .Values.backend.id | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{- define "inference-backend.labels" -}}
app.kubernetes.io/name: {{ include "inference-backend.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: inference-backend
app.kubernetes.io/part-of: llm-inference-platform
app.kubernetes.io/managed-by: Helm
backend-id: {{ .Values.backend.id | quote }}
{{- end -}}

{{- define "inference-backend.selectorLabels" -}}
app.kubernetes.io/name: {{ include "inference-backend.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
backend-id: {{ .Values.backend.id | quote }}
{{- end -}}

{{- define "inference-backend.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
{{- default (include "inference-backend.fullname" .) .Values.serviceAccount.name -}}
{{- else -}}
{{- default "default" .Values.serviceAccount.name -}}
{{- end -}}
{{- end -}}
