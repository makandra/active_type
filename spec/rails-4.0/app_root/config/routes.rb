# encoding: utf-8

SpecApp::Application.routes.draw do
  get ':controller(/:action(/:id(.:format)))'
end
