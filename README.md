# Zabbix Agent Ansible Deployer

Автоматизированное кроссплатформенное развёртывание и конфигурация **Zabbix Agent 2** с использованием **Ansible** и **GitLab CI/CD**.

Проект предназначен для централизованной установки и сопровождения Zabbix Agent 2 в смешанной инфраструктуре, включающей Linux, Windows Server и Arch Linux.

## Возможности

- Автоматизированная установка и конфигурация Zabbix Agent 2
- Поддержка Linux и Windows Server
- Отдельная логика установки для Arch Linux
- Развёртывание через GitLab CI/CD
- Управление конфигурацией через Ansible
- Поддержка пользовательских Zabbix UserParameters
- Доставка собственных monitoring-скриптов
- Автоматический перезапуск Zabbix Agent при изменении конфигурации
- Разделение конфигурации инфраструктуры и логики автоматизации
- Возможность расширения под разные окружения

## Архитектура

```text
GitLab CI/CD
     │
     ▼
   Ansible
     │
     ├── Linux hosts
     │     ├── Zabbix Agent 2
     │     └── Custom UserParameters
     │
     ├── Arch Linux hosts
     │     └── Установка через pacman
     │
     └── Windows hosts
           ├── Zabbix Agent 2
           └── PowerShell / custom checks
```

GitLab CI/CD используется как точка запуска deployment-процесса.

Ansible отвечает за:

- установку Zabbix Agent;
- настройку подключения к Zabbix Server;
- доставку пользовательских конфигураций;
- размещение monitoring-скриптов;
- перезапуск сервисов при изменении конфигурации.

## Структура репозитория

```text
.
├── .github/
│   └── workflows/
│       └── lint.yml
├── .gitlab-ci.yml
├── .gitignore
├── README.md
├── SECURITY.md
├── ansible.cfg
└── ansible/
    ├── configs/
    │   └── default/
    │       ├── linux/
    │       │   ├── scripts/
    │       │   └── zabbix_agent2.d/
    │       └── windows/
    │           ├── scripts/
    │           └── zabbix_agent2.d/
    ├── group_vars/
    │   └── all.yml
    ├── inventory/
    │   └── example.ini
    ├── roles/
    │   ├── zabbix_agent_wrapper/
    │   └── zabbix_custom_checks/
    ├── playbook.yml
    └── requirements.yml
```

## Основные компоненты

### `zabbix_agent_wrapper`

Wrapper-role для установки и конфигурации Zabbix Agent 2.

Использует готовую роль из коллекции `community.zabbix`, а также содержит дополнительную логику для платформ, требующих отдельного сценария установки.

### `zabbix_custom_checks`

Роль для доставки пользовательских monitoring-скриптов и Zabbix UserParameters.

Позволяет хранить кастомные проверки централизованно и распространять их вместе с основной конфигурацией агента.

## Требования

Для локального запуска необходимы:

- Python 3
- Ansible
- SSH-доступ к Linux-хостам
- WinRM или SSH/OpenSSH-доступ к Windows-хостам
- доступ к целевым Zabbix Agent hosts

Необходимые Ansible collections устанавливаются из:

```text
ansible/requirements.yml
```

Установка:

```bash
ansible-galaxy collection install -r ansible/requirements.yml
```

## Inventory

В репозитории используется только пример inventory.

```ini
[linux]
linux-node-01 ansible_host=192.0.2.10
linux-node-02 ansible_host=192.0.2.11

[windows]
windows-node-01 ansible_host=192.0.2.20

[all:vars]
ansible_user=deployer
```

Для реального окружения необходимо создать собственный inventory.

Не рекомендуется хранить реальные IP-адреса, hostname, логины или другую чувствительную инфраструктурную информацию в публичном репозитории.

## Конфигурация

Основные переменные находятся в:

```text
ansible/group_vars/all.yml
```

Например:

```yaml
zabbix_agent_server:
  - zabbix.example.internal

zabbix_agent_serveractive:
  - zabbix.example.internal
```

Таким образом адреса Zabbix Server и другие environment-specific параметры не захардкожены непосредственно в playbook.

## Запуск вручную

Для проверки доступности hosts:

```bash
ansible all -i ansible/inventory/example.ini -m ping
```

Запуск playbook:

```bash
ansible-playbook \
  -i ansible/inventory/example.ini \
  ansible/playbook.yml
```

Перед запуском необходимо заменить example inventory и значения конфигурации на соответствующие вашему окружению.

## GitLab CI/CD

Проект содержит пример автоматизированного deployment через GitLab CI/CD.

Общий workflow:

```text
Commit / Manual Pipeline
          │
          ▼
Установка Ansible dependencies
          │
          ▼
Подготовка SSH credentials
          │
          ▼
      ansible-playbook
          │
          ▼
Установка Zabbix Agent
          │
          ▼
Доставка конфигурации и custom checks
          │
          ▼
Перезапуск сервиса при необходимости
```

Infrastructure deployment запускается вручную, чтобы избежать случайного изменения конфигурации production-хостов после каждого commit.

## CI/CD Variables

Чувствительные данные не должны храниться непосредственно в `.gitlab-ci.yml`.

SSH private key, `known_hosts` и другие credentials рекомендуется передавать через защищённые GitLab CI/CD Variables.

Например:

```text
DEPLOYER_SSH_KEY
SSH_KNOWN_HOSTS
```

Для production-окружений также рекомендуется использовать protected variables и protected branches/environments.

## Пользовательские проверки

Проект поддерживает доставку собственных Zabbix checks.

### Linux

Скрипты:

```text
/usr/local/bin/zabbix_custom_scripts/
```

UserParameters:

```text
/etc/zabbix/zabbix_agent2.d/
```

### Windows

Скрипты:

```text
C:\Program Files\Zabbix Agent 2\scripts\
```

UserParameters:

```text
C:\Program Files\Zabbix Agent 2\zabbix_agent2.d\
```

Это позволяет хранить пользовательские проверки в Git и доставлять их через тот же Ansible workflow, который используется для установки и настройки агента.

## Пример custom check

Linux:

```bash
#!/usr/bin/env bash

uptime -p
```

Zabbix UserParameter:

```text
UserParameter=custom.system.uptime,/usr/local/bin/zabbix_custom_scripts/check_uptime.sh
```

После доставки конфигурации Ansible handler автоматически перезапускает Zabbix Agent.

## Проверка качества кода

Репозиторий содержит GitHub Actions workflow для проверки Ansible-кода.

В CI могут выполняться:

```text
ansible-lint
yamllint
```

Это позволяет проверять изменения до их попадания в основную ветку.

## Безопасность

Публичная версия проекта не содержит:

- реальных credentials;
- SSH private keys;
- внутренних IP-адресов;
- production hostname;
- корпоративных доменов;
- логов инфраструктуры;
- production inventory;
- сертификатов и private keys.

Для примеров используются синтетические адреса и hostname.

Секреты должны передаваться через:

- GitLab CI/CD Variables;
- Ansible Vault;
- Vault / Secret Manager;
- другое внешнее хранилище секретов.

Дополнительные рекомендации находятся в `SECURITY.md`.

## Используемые технологии

- Ansible
- Zabbix Agent 2
- GitLab CI/CD
- GitHub Actions
- Linux
- Windows Server
- Arch Linux
- PowerShell
- Bash
- SSH
- Git

## Для чего создавался проект

Проект демонстрирует подход к автоматизации эксплуатации Zabbix Agent в неоднородной инфраструктуре.

Основные задачи:

- минимизировать ручную установку агентов;
- унифицировать конфигурацию Linux и Windows hosts;
- хранить monitoring-конфигурацию в Git;
- централизованно доставлять custom checks;
- использовать repeatable и idempotent deployment;
- интегрировать configuration management с CI/CD.

Публичная версия является обобщённой реализацией и не содержит данных конкретной инфраструктуры.

## Возможные направления развития

Проект можно расширить:

- поддержкой нескольких environments;
- Ansible Vault;
- Molecule tests;
- дополнительными Zabbix templates;
- автоматической регистрацией hosts через Zabbix API;
- интеграцией с HashiCorp Vault;
- deployment через GitOps-подход;
- Prometheus-compatible custom exporters;
- автоматизированным тестированием Linux и Windows roles.
