Этот модуль повершелл разработан для получения детальной информации о инфраструктуре zVirt

Требования: Powershell 7.4

Функции:

- Connect-zVirtController
  
  Назначение - добавление администрируемого контроллера;
  
  Входные данные:
  
  Обязательный $user - логин;
  
  Обязательный $domain - домен (в случае стандартного админского аккаунта internal);
  
  Обязательный $secret - пароль;
  
  Обязательный $apiURL - адрес Zvirt в формате <<https://zvirt.local>>;
  
  Выходные данные - RawContent; связка адрес + куки


- Get-zVirtConnectedControllers
  
  Назначение - получение списка администрируемых контроллеров;
  
  Выходные данные - связка адрес + куки
  

- Disconnect-zVirtController
  
  Назначение - добавление администрируемого контроллера;
  
  Входные данные: Обязательный $apiURL - адрес Zvirt в формате <<https://zvirt.local>>;
  
  Выходные данные - связка адрес + куки
  


- Get-zVirtHosts
  
  Назначение - Получение списка гипервизоров;
  
  Входные данные: Необязательный $name - имя гипервизора;
  
  Выходные данные :
  
  {"Name" ;"ip";"os";"memory";"CPU"=;"serial number";"cluster";"state"; "RAWData"}


- Get-zVirtStores
  
  Назначение - Получение списка хранилищ;
  
  Входные данные: Необязательный $name - имя хранилища;
  
  Выходные данные :
  
  {"Name";"type";"total";"available";"used"; "RAWData"}
  

- Get-zVirtVMs
  
  Назначение - Получение списка VM;
  
  Входные данные: Необязательный $name - имя VM; Необязательный $ID - ид VM
  
  Выходные данные :
  
  {"NameVM";"description";"comment";"cpu";"memory";"cluster";"disk_attachments"=;"host_devices";"nics"; "RAWData"}
  

- Get-zVirtVMDisks
  
  Назначение - Получение списка дисков VM;
  
  Входные данные: необязательный $VMName - имя VM;
  
  Выходные данные :
  
  {"NameVM" ;"disk_size" ;"storage_type";"status"; "RAWData"}
