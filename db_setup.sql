CREATE USER 'photoview'@'localhost' IDENTIFIED BY 'photosecret';
CREATE DATABASE photoview;
GRANT ALL PRIVILEGES ON photoview.* TO 'photoview'@'localhost';
FLUSH PRIVILEGES;