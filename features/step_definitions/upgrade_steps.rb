# Copyright (c) 2011, 2012, 2013, 2014 Solano Labs All Rights Reserved

Given /^my gem is out of date$/ do
  Antilles.install(:get, "/1/suites/user_suites", {:status=>1, :explanation=>"solano-preview-0.9.4 is out of date."}, :code=>426)
end
