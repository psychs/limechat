<?php

$to = 'psychs@limechat.net';
$from = 'psychs@limechat.net';

$subject = '[CRASH LOG] ' . $_POST['app_name'];
$divider = "\n\n=========================================================================\n\n";
$message = "\n" . $_POST['comment'] . $divider . $_POST['crash_log'];

$headers = 'From: ' . $from . "\n" .
						'Reply-To: ' . $from . "\n" .
            "Content-Transfer-Encoding: 8bit\n" .
            "Content-Type: text/plain; charset=UTF-8\n" .
            "List-Id: limechat-crash\n" .
            'X-Mailer: PHP/' . phpversion();

mail($to, $subject, $message, $headers);

?>
