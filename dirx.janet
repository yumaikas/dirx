(import spork/rawterm :as rawterm)


(defn table/take [d to-take] (tabseq [k :in to-take] k (d k)))

(defn dir/print [d] (print (d :d)))
(defn dir-objs [] (as-> (os/dir ".") it
                        (filter (fn [d] (not (string/has-prefix? "." (d :d)))) it)
                        (sort-by |($ :d) it)
                        (reverse! it)
                        (map |(table/take (merge { :name $ } (os/stat $)) [:name :mode ]) it)
                        ))

(defn get-len [d] (length (d :d)))
(defn stats [dirs] 
  (def [_ cols] (rawterm/size))
  (def dir-lens (map get-len dirs))
  (def max-name-len (+ (max-of dir-lens) 2))
  (def cells-per-line (max (div (- cols 5) max-name-len) 1))
  (def total-len (+ (sum dir-lens) (* (- (length dirs) 1) 2)))

  (if (> (- cols 5) total-len)
    { {:num-lines 1 :cells-per-line (inc (length dirs)) :max-name-len max-name-len} }
    {
      :max-name-len max-name-len
      :cells-per-line cells-per-line
      :num-lines (div (length dirs) cells-per-line) }
  ))

(defn prep-fmt [max-w] 
  {
   :file (string "\e37m%-" max-w "s\e38m")
   :directory (string "\e36m%-" max-w "s\e38m")
   })

(defn write-entry [entry fmt] 
  (cond 
    (= (entry :mode) :file) (printf (fmt :file) (entry :name))
    (= (entry :mode) :directory) (printf (fmt :directory) (entry :name))
    (print (str "Unsupported fs mode " (entry :mode)))
    ))


(defn main [exe & _]  
  (def dirs (dir-objs))

  (when (= (length dirs) 0) (print "Empty dir") (break))
  (def info (stats dirs))
  (def fmt (prep-fmt (info :max-name-len)))

  (def outs (partition (info :cells-per-line) dirs))

  (def colWidths
    (seq [col :in outs]
      (max-of (map |(length ($ :name)) col))))

  

  (each d dirs
    (:print d)
    (pp (os/stat (d :d))))

  )
