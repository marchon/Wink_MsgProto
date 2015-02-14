<?php
require '../Slim/Slim.php';
\Slim\Slim::registerAutoloader();


$app = new \Slim\Slim();
$app->get('/', function() {
    $app = \Slim\Slim::getInstance();

    if (empty($app->request->params('m'))) { return; }

    $data = wink('aprontest -m {m} -l');
    $app->response->headers->set('Content-Type', 'application/json');
    $app->response->setBody(json_encode($data));
});

$app->post('/', function() {
    $app = \Slim\Slim::getInstance();

    if (empty($app->request->params('m')) ||
        empty($app->request->params('t')) ||
        empty($app->request->params('v'))) { return; }

    $data = wink('aprontest -m {m} -t {t} -v {v} -u');
    $app->response->headers->set('Content-Type', 'application/json');
    $app->response->setBody(json_encode($data));
});

$app->run();

function wink($cmd) {
    $app = \Slim\Slim::getInstance();

    # The needed variables
    $m = $app->request->params('m');
    $t = $app->request->params('t');
    $v = $app->request->params('v');

    $cmd = str_replace('{m}', escapeshellarg($m), $cmd);
    $cmd = str_replace('{t}', escapeshellarg($t), $cmd);
    $cmd = str_replace('{v}', escapeshellarg($v), $cmd);
    $cmd .= " | sed -e '1,/ATTRIBUTE/d' | sed -e '/^\$/d' | awk -F '|' '{gsub(/^[ ]+/,\"\",\$1); gsub(/[ ]+\$/,\"\",\$1); gsub(/^[ ]+/,\"\",\$6); gsub(/[ ]+\$/,\"\",\$6); print \$1\",\"\$6}'";

    $output = trim(shell_exec($cmd));
    $data = [];
    foreach(str_getcsv($output, "\n") as $row) {
        $_data = str_getcsv($row, ",");
        $data[$_data[0]] = $_data[1];
    }

    return $data;
}
