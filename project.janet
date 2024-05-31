(declare-project 
  :name "dirx"
  :description "Simple cross platform directory lister that outputs a vertically alphabetized grid"
  :author "Andrew Owen <yumaikas94@gmail.com>"
  :dependencies ["spork"])


(declare-executable :name "lx" :entry "dirx.janet")

