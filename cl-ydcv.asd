(defsystem :cl-ydcv
  :serial t
  :depends-on (#:dexador
	       #:clache
	       #:cl-readline
               #:crypto-shortcuts
	       #:jonathan
	       #:uuid
	       #:local-time)
  :components ((:file "package")
               (:file "ydcv")))
