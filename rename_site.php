<?php
// WP_DB_NAME=wp_scratch WP_DB_USER=wp_scratch WP_DB_PASS=wp_scratch WP_DB_HOST=localhost php ./rename_site.php
// WP_DB_NAME=wp_scratch WP_DB_USER=wp_scratch WP_DB_PASS=wp_scratch WP_DB_HOST=localhost ./wp --path=/usr/share/wp_cr_loc/ search-replace http://xxx.de/ http://yyy:81/
/*
  The "Home" setting is the address you want people to type in their browser to reach your WordPress blog.
  The "Site URL" setting is the address where your WordPress core files reside.
  Both settings should include the http:// part and should not have a slash "/" at the end.
*/

if (isset($_SERVER['HTTP_HOST'])) {
    $new_home = "http://".$_SERVER['HTTP_HOST']."/";
}  else {
    $new_home = "http://localhost/";// Testing
}

// dirname(__FILE__)."/"
$wp_dir = "/usr/share/wordpress/";
$mysql_host = getenv('WP_DB_HOST');
$mysql_username = getenv('WP_DB_USER');
$mysql_password = getenv('WP_DB_PASS');
$mysql_database = getenv('WP_DB_NAME');

$query = "select option_name,option_value from wp_options where option_name in ('home')";//,'siteurl')";
$con = mysqli_connect($mysql_host, $mysql_username, $mysql_password, $mysql_database) or die('Error connecting to MySQL server: ' . mysql_error());
$result = mysqli_query($con, $query);

while($row = mysqli_fetch_array($result)) {
    // echo $row['option_name'] . " " . $row['option_value'] . "\n";
    // http://php.net/manual/de/function.exec.php
    $cmd = "WP_DB_NAME=".$mysql_database." WP_DB_USER=".$mysql_username." WP_DB_PASS=".$mysql_password." WP_DB_HOST=".$mysql_host." ".$wp_dir."wp --path=".$wp_dir." search-replace ".$row['option_value']." $new_home 2>/tmp/phperr.log";
    $v = exec($cmd, $out, $rv);
    // echo "$cmd $v $rv $out";
}
mysqli_close($con);
// unlink($wp_dir."index.php");
unlink($wp_dir."wp");
copy($wp_dir."index.php-orig","index.php");
unlink($wp_dir."index.php-orig");
if (isset($_SERVER['HTTP_HOST'])) header("Location: ".$new_home);

?>