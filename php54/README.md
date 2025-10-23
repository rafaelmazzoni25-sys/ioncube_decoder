# Legacy PHP runtime placeholder

Coloque aqui um ambiente PHP 5.x portátil contendo pelo menos:

- `php-cgi.exe`
- `php.ini`
- a pasta `ext` com as extensões utilizadas pelo runtime

Os scripts de decodificação assumem o layout `php54\php-cgi.exe -c php54\php.ini`. Caso
utilize outra estrutura, defina a variável de ambiente `IONCUBE_DECODER_PHP54` antes de
executar o `functions-decoder.sh` para apontar para o comando correto.

Certifique-se de que o `php.ini` carregue o loader adequado usando as variáveis de ambiente
já esperadas pelo kit (caso organize os arquivos em outro local, ajuste também as variáveis
`IONCUBE_DECODER_LOADER_54`, `IONCUBE_DECODER_ZEND_MANAGER_54` e
`IONCUBE_DECODER_ZEND_OPTIMIZER_54`):

```
zend_extension = "${IONCUBE_LOADER}"
zend_extension_ts = "${IONCUBE_ZEND_MANAGER}"
zend_extension_manager.optimizer_ts = "${IONCUBE_ZEND_OPTIMIZER}"
```

Também é necessário disponibilizar o arquivo `ioncube\ioncube_loader_win_5.4.dll` (ou a
versão correspondente à build do PHP 5.x utilizada). Caso o decoder sinalize que o runtime
ou o loader estão ausentes, basta extrair os binários na estrutura acima e executar o
processo novamente.
