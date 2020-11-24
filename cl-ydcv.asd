(defsystem :cl-ydcv
  :serial t
  :depends-on (#:dexador
               #:crypto-shortcuts
	       #:jonathan
	       #:uuid
	       #:local-time)
  :components ((:file "package")
               (:file "ydcv")))
