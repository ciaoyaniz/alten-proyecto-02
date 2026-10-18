try {
    var params = JSON.parse(value);

    ['jira_url', 'jira_user', 'jira_token', 'project_key', 'issue_type', 'summary', 'description']
        .forEach(function (nombre) {
            if (typeof params[nombre] !== 'string' || params[nombre].trim() === '') {
                throw 'falta el parámetro "' + nombre + '"';
            }
        });

    if (params.event_value === '0') {
        return 'Recuperación: no se crea ticket';
    }

    var guias = {
        cpu: params.confluence_cpu,
        ram: params.confluence_ram,
        disco: params.confluence_disco
    };
    var guia = guias[params.guia] || params.confluence_default || '';

    var descripcion = params.description;
    if (guia !== '') {
        descripcion += '\n\nGuía de resolución: ' + guia;
    }

    var ticket = {
        fields: {
            project: { key: params.project_key },
            issuetype: { name: params.issue_type },
            summary: params.summary,
            description: descripcion,
            labels: ['zabbix']
        }
    };

    var request = new HttpRequest();
    request.addHeader('Content-Type: application/json');
    request.addHeader('Authorization: Basic ' + btoa(params.jira_user + ':' + params.jira_token));

    var url = params.jira_url.replace(/\/+$/, '') + '/rest/api/2/issue';
    var respuesta = request.post(url, JSON.stringify(ticket));
    var estado = request.getStatus();

    if (estado !== 201) {
        throw 'Jira respondió HTTP ' + estado + ': ' + respuesta;
    }

    return JSON.stringify({ tags: { jira: JSON.parse(respuesta).key } });
}
catch (error) {
    Zabbix.log(3, '[Webhook de Jira] ' + error);
    throw 'No se creó el ticket: ' + error;
}

// Opciones configuradas:
// ----------------------
// JSON.parse(value) -> Zabbix pasa los parámetros como texto JSON
// lista con forEach -> si falta uno de los siete obligatorios el error dice cuál
// event_value === '0' -> en la recuperación no llama a Jira
// guias[params.guia] -> enlace de Confluence según la etiqueta guia del problema
// || confluence_default || '' -> sin etiqueta conocida, la portada de OPS o nada
// '\n\nGuía de resolución: ' -> línea en blanco y el enlace al final del texto
// project.key y issuetype.name -> proyecto ZBX y tipo Tarea de los parámetros
// labels: ['zabbix'] -> separa los tickets automáticos de los míos
// new HttpRequest() -> objeto HTTP de Zabbix; Duktape no tiene fetch
// btoa(usuario:token) -> autenticación básica; Base64 no cifra, cifra el https
// replace(/\/+$/, '') + '/rest/api/2/issue' -> quita la barra final; API v2 que crea tickets
// estado !== 201 -> si Jira no crea el ticket, error con su respuesta
// tags: { jira: key } -> con Process tags el problema guarda jira: ZBX-n
// Zabbix.log(3, ...) -> el error queda en docker logs zabbix-server
// throw en el catch -> el envío sale Failed en Action log con el motivo