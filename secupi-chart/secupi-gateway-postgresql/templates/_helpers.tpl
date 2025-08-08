{{/*
Expand the name of the chart.
*/}}
{{- define "secupi_common.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "secupi_common.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "images.gateway" -}}
{{- $repo := .Values.image.repository }}
{{- printf "%s/%s:%s" $repo .Values.image.name .Values.image.tag -}}
{{- end }}

{{/*
Common labels
*/}}
{{- define "secupi_common.labels" -}}
helm.sh/chart: {{ include "secupi_common.chart" . }}
{{ include "secupi_common.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "secupi_common.selectorLabels" -}}
app.kubernetes.io/name: {{ include "secupi_common.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}



{{- define "secupi_gateway.name" -}}
{{- printf "%s-gateway" .Release.Name | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "secupi_gateway_backend_config.name" -}}
{{- printf "%s-backendconfig" .Release.Name | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "secupi_gateway_hz_service.name" -}}
{{ include "secupi_gateway.name" . }}-hazelcast
{{- end }}

{{- define "secupi_gateway_keystore.secret.name" -}}
{{- printf "%s-gateway-keystore" .Release.Name | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "secupi_gateway_truststore.secret.name" -}}
{{- printf "%s-gateway-truststore" .Release.Name | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "secupi_gateway.label" -}}
{{ include "secupi_gateway.name" . }}
{{- end }}

{{- define "secupi_gateway_port" -}}
{{ .Values.gateway.port }}
{{- end }}

{{- define "secupi_gateway_target_port" -}}
{{ .Values.gateway.env.GATEWAY_PORT | default "5432" }}
{{- end }}

{{- define "secupi_gateway_replicas" -}}
{{ .Values.gateway.replicaCount }}
{{- end }}

{{- define "kubernetes_dnsdomain" -}}
{{ .Values.kubernetesDNSDomain | default (printf "cluster.local") }}
{{- end }}

{{- define "secupi_service_account.name" -}}
{{- .Release.Name | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Security extensions
Pod level
*/}}

{{- define "spec.securityContext" -}}

{{- if .Values.openshift.enabled }}

    {{- if .Values.openshift.securityContextEnabled }}
securityContext:
  runAsNonRoot: true
  fsGroup: 10001
  runAsUser: 10001 
  runAsGroup: 10001
  fsGroupChangePolicy: "OnRootMismatch"
  seccompProfile:
    type: RuntimeDefault
    {{- end }}

{{- else }}

  {{- if eq (.Values.default.securityContext.version | toString) "1" }}
securityContext:
  fsGroup: 999

  {{- else if eq (.Values.default.securityContext.version | toString) "2" }}
automountServiceAccountToken: false
securityContext:
  fsGroup: 10001
  runAsUser: 10001 
  runAsGroup: 10001
  fsGroupChangePolicy: "OnRootMismatch"

{{/* For future settings, example
    {{- else if eq (.Values.default.securityContext.version | toString) "3" }}
*/}}

  {{- end }}
{{- end }}
{{- end }}

{{/*
Security extensions
Containter level
*/}}

{{- define "containter.securityContext" -}}

{{- if .Values.openshift.enabled }}

  {{- if .Values.openshift.securityContextEnabled }}
securityContext:
  allowPrivilegeEscalation: false
  readOnlyRootFilesystem : true
  capabilities:
    drop: ["ALL"]
  {{- end }}

{{- else -}}

  {{- if eq (.Values.default.securityContext.version | toString) "1" }}

  {{- else if eq (.Values.default.securityContext.version | toString) "2" }}  
securityContext:
  allowPrivilegeEscalation: false
  readOnlyRootFilesystem : true
  capabilities:
    drop: ["ALL"]
    

{{/* For future settings, example
    {{- if eq (.Values.default.securityContext.version | toString) "3" }}
*/}}

  {{- end }}
      
{{- end }}
{{- end }}

{{- define "resources" -}}
{{- $clusterSizeType := .ClusterSizeType | default "mid" -}}
{{- $base := default (dict "limits" (dict) "requests" (dict)) .Resources -}}
{{- $resources := ternary $base (index $base $clusterSizeType) (not (empty $base.limits)) | default (dict "limits" (dict) "requests" (dict)) -}}
resources:
{{- if or $resources.limits.memory $resources.limits.cpu $resources.limits.ephemeral_storage }}
  limits:
    {{- if $resources.limits.memory }}
    memory: {{ $resources.limits.memory }}
    {{- end }}
    {{- if $resources.limits.cpu }}
    cpu: {{ $resources.limits.cpu }}
    {{- end }}
    {{- if $resources.limits.ephemeral_storage }}
    ephemeral-storage: {{ $resources.limits.ephemeral_storage }}
    {{- end }}
{{- end }}
{{- $resources := ternary $base (index $base $clusterSizeType) (not (empty $base.requests)) | default (dict "limits" (dict) "requests" (dict)) }}
{{- if or $resources.requests.memory $resources.requests.cpu $resources.requests.ephemeral_storage }}
  requests:
    {{- if $resources.requests.memory }}
    memory: {{ $resources.requests.memory }}
    {{- end }}
    {{- if $resources.requests.cpu }}
    cpu: {{ $resources.requests.cpu }}
    {{- end }}
    {{- if $resources.requests.ephemeral_storage }}
    ephemeral-storage: {{ $resources.requests.ephemeral_storage }}
    {{- end }}
{{- end }}
{{- end }}
