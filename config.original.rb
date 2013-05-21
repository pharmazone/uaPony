$db_user = 'root';
$db_name = 'ua_post';

$email = 'EMAIL_ADRESS'
$email_password = 'PASSWORD'

$mail_transport = :smtp
$mail_options = {
    :address              => 'smtp.gmail.com',
    :port                 => '587',
    :enable_starttls_auto => true,
    :user_name            => $email,
    :password             => $email_password,
    :authentication       => :plain, # :plain, :login, :cram_md5, no auth by default
    :domain               => "localhost.localdomain" # the HELO domain provided by the client to the server
}
