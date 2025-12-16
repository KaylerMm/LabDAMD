#!/bin/bash

echo "📊 COMPARAÇÃO DE DADOS - SERVIDOR vs DISPOSITIVO"
echo "=============================================="
echo

# 1. Extrair dados do dispositivo
echo "📱 1. Extraindo dados do dispositivo..."
adb shell "run-as com.example.task_manager cat /data/data/com.example.task_manager/databases/task_manager_v2.db" > /tmp/task_manager_celular.db

if [ $? -eq 0 ]; then
    echo "   ✅ Banco do dispositivo extraído para: /tmp/task_manager_celular.db"
else
    echo "   ❌ Falha ao extrair banco do dispositivo"
    exit 1
fi

echo

# 2. Contar tasks no SERVIDOR
echo "🖥️  2. Dados do SERVIDOR:"
servidor_db="/home/kayler/Puc/Lab App Mov/Roteiro1/database/tasks.db"

if [ ! -f "$servidor_db" ]; then
    echo "   ❌ Banco do servidor não encontrado: $servidor_db"
    exit 1
fi

sqlite3 "$servidor_db" -header -column "
SELECT
  COUNT(*) as total_servidor,
  SUM(CASE WHEN completed = 1 THEN 1 ELSE 0 END) as completas_servidor,
  SUM(CASE WHEN completed = 0 THEN 1 ELSE 0 END) as pendentes_servidor
FROM tasks;"

echo

# 3. Contar tasks no DISPOSITIVO
echo "📱 3. Dados do DISPOSITIVO:"
sqlite3 /tmp/task_manager_celular.db -header -column "
SELECT
  COUNT(*) as total_dispositivo,
  SUM(CASE WHEN completed = 1 THEN 1 ELSE 0 END) as completas_dispositivo,
  SUM(CASE WHEN completed = 0 THEN 1 ELSE 0 END) as pendentes_dispositivo,
  SUM(CASE WHEN needsSync = 1 THEN 1 ELSE 0 END) as nao_sincronizadas
FROM tasks;"

echo

# 4. Listar tasks do servidor
echo "🗂️  4. Tasks no SERVIDOR (primeiras 5):"
sqlite3 "$servidor_db" -header -column "
SELECT id, title, completed, createdAt
FROM tasks 
ORDER BY createdAt DESC 
LIMIT 5;"

echo

# 5. Listar tasks do dispositivo
echo "📋 5. Tasks no DISPOSITIVO (primeiras 5):"
sqlite3 /tmp/task_manager_celular.db -header -column "
SELECT id, serverId, title, completed, needsSync, createdAt
FROM tasks 
ORDER BY createdAt DESC 
LIMIT 5;"

echo

# 6. Análise de sincronização
echo "🔄 6. ANÁLISE DE SINCRONIZAÇÃO:"
echo

echo "   Tasks não sincronizadas no dispositivo:"
sqlite3 /tmp/task_manager_celular.db -header -column "
SELECT id, title, completed, needsSync
FROM tasks 
WHERE needsSync = 1;"

echo
echo "   Tasks sem serverId (criadas offline):"
sqlite3 /tmp/task_manager_celular.db -header -column "
SELECT id, title, completed, serverId
FROM tasks 
WHERE serverId IS NULL;"

echo

# 7. Limpeza
echo "🧹 7. Limpando arquivos temporários..."
rm -f /tmp/task_manager_celular.db
echo "   ✅ Arquivo temporário removido"

echo
echo "✅ Análise completa!"