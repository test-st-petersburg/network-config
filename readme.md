# Сценарии для настройки маршрутизаторов и базовых сетевых сервисов

[![GitHub release](https://img.shields.io/github/release/test-st-petersburg/network-config.svg)](https://github.com/test-st-petersburg/network-config/releases)

Данный проект - сценарии для настройки сетевого окружения учреждени. В том числе:

- маршрутизаторов
- туннелей между подсетями
- DHCP серверов
- DNS серверов (в перспективе)

## Подготовка среды

Для внесения изменений в пакет и повторной сборки проекта потребуются следующие продукты:

Под Windows:

- текстовый редактор, настоятельно рекомендую [VSCode][]

Под Linux:

- [PowerShellCore][]
- [VSCode][]

Для [VSCode][] рекомендую установить расширения, указанные в рабочей области.

Существенно удобнее будет работать с репозиторием, имея установленный `git`.

Далее следует скопировать репозиторий проекта либо как zip архив из [последнего
релиза](https://github.com/Metrolog/test-st-petersburg/network-config), либо клонировав git репозиторий.
Последнее - предпочтительнее.

Для подготовки среды (установки необходимых приложений)
следует воспользоваться сценарием `install.ps1` (запускать от имени администратора):

    install\install.ps1 -Scope Machine -GUI -Verbose

либо

    install\install.cmd

Указанный сценарий установит все необходимые компоненты.

Для интерактивного контроля процесса установки можно использовать параметр `-Confirm`:

    install\install.ps1 -Scope Machine -GUI -Verbose -Confirm

Указанный параметр вынуждает сценарий перед внесением любых изменений запрашивать
подтверждение у пользователя.

Для дальнейшей работы необходимо включить в переменную `PATH`
каталоги с исполняемыми файлами установленных средств.
Если Вы работаете не под учётной записью администратора, тогда Вам так же
потребуется выполнить `install.ps1` для изменения переменной окружения `PATH` для
Вашей учётной записи:

    install\install.ps1 -Scope User -Verbose

либо

    install\install_for_user.cmd

## Внесение изменений

Репозиторий проекта размещён по адресу [github.com/test-st-petersburg/network-config](https://github.com/test-st-petersburg/network-config).
Стратегия ветвления - Git Flow.

При необходимости внесения изменений в сам проект предложите Pull Request в основной
репозиторий в ветку `develop`.

[VSCode]: https://code.visualstudio.com/ "Visual Studio Code"
[PowerShellCore]: https://github.com/PowerShell/PowerShell "PowerShell Core"
