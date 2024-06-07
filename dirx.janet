(import spork/rawterm :as rawterm)

(defn table/take [d to-take] (tabseq [k :in to-take] k (d k)))

(defn show? [opts entry] 
  (cond
    (get opts :all nil) true
    true (not 
           (or
             (string/has-prefix? "." entry)
             (string/has-prefix? "#" entry)
             (string/has-prefix? "$" entry)
             (not= (string/find "NTUSER." entry) nil)
             (not= (string/find "ntuser." entry) nil)))))

(defn stat-entry [opts path] 
  (if (get opts :debug) 
    (put (or (os/stat path) @{}) :name path)
    (table/take (put (or (os/stat path) @{}) :name path) [ :name :mode])))

(defn dir-objs [opts] 
  (def dir (get opts :dir "."))
  (os/cd dir)
  (as-> (or (os/dir ".") (error (string "Unable to list " (os/cwd)))) it
        (filter (partial show? opts) it)
        (sort it)
        (map (partial stat-entry opts) it)
        (filter (fn [d] (get d :mode nil)) it)
        ))

(defn get-len [d] (length (d :name)))
(defn stats [dirs] 
  (def [_ cols] (rawterm/size))
  (def dir-lens (map get-len dirs))
  (def max-name-len (+ (max-of dir-lens) 2))
  (def cells-per-line (max (div (- cols 3) max-name-len) 1))
  (def total-len (+ (sum dir-lens) (* (- (length dirs) 1) 2)))

  (if (> (- cols 5) total-len)
    {:num-lines 1 :cells-per-line (length dirs) :max-name-len max-name-len}
    {
      :max-name-len max-name-len
      :cells-per-line (inc cells-per-line)
      :num-lines (div (length dirs) cells-per-line) }
  ))

(defn prep-fmt [] 
  {
   :file (fn [w] (string "\e[37m%-" w "s\e[39m  "))
   :directory (fn [w] (string "\e[36m%-" w "s\e[39m  "))
   :default (fn [w] (string "\e[31m%-" w "s\e[39m  "))
   })

(defn write-entry [entry fmt w] 
  (cond 
    (= (entry :mode) :file) (prinf ((fmt :file) w) (entry :name))
    (= (entry :mode) :directory) (prinf ((fmt :directory) w) (entry :name))
    true (prinf ((fmt :default) w) (entry :name))
    ))

(defn args-to-opts [args opts] 
  (match args
    ["-a"] (args-to-opts (slice args 1) (merge opts {:all true}))
    ["--all"] (args-to-opts (slice args 1) (merge opts {:all true}))
    ["--debug"] (args-to-opts (slice args 1) (merge opts {:debug true}))
    [dir] (args-to-opts (slice args 1) (merge opts {:dir dir}))
    _ (if (> (length args) 0)
        (error (string "Unsupport arguments: " args))
        opts)
    ))


(defn main [exe & args]  
  (def opts (args-to-opts args {}))
  (def dirs (dir-objs opts))

  (when (= (length dirs) 0) (print "Empty dir") (break))
  (def info (stats dirs))
  (def fmt (prep-fmt))

  (def outs (partition (info :num-lines) dirs))

  (def colWidths
    (seq [col :in outs]
      (+ 2 (max-of (map |(length ($ :name)) col)))))
  (when (get opts :debug)
    (each o outs (pp o))
    (pp opts)
    (pp colWidths)
    (pp info))

  (loop [lineIdx :range [0 (info :num-lines)]
         :after (print)
         colIdx :range [0 (length outs)]]
    (def entry (get-in outs [colIdx lineIdx] nil))
    (when entry
      (write-entry entry fmt (colWidths colIdx)))))
