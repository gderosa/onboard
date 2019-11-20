# Sometimes errors in setup leave the system with no Internet connection: this may sort it.
cd $PROJECT_ROOT
su $APP_USER -c "ruby onboard.rb --restore-dns"
