# encoding: utf-8

SpecApp::Application.routes.draw do
  match ':controller(/:action(/:id(.:format)))'
end
