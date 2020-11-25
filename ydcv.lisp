(in-package :cl-ydcv)

(defvar app-id "281fc92dfed3dc9f")
(defvar app-key "AGlLEKYhKv8RosZ3DulAAYnZLwVMNO3A")

(defun input (q)
  (let ((length (length q)))
    (if (> length 20)
	(concatenate
	 'string
	 (subseq q 0 10)
	 (write-to-string length)
	 (subseq q (- length 10) length))
	q)))

(defun yd (word)
  (let* ((salt (write-to-string (uuid:make-v1-uuid)))
	 (time (write-to-string (local-time:timestamp-to-unix (local-time:now))))
	 (sign (cryptos:sha256
		(concatenate
		 'string
		 app-id (input word) salt time app-key))))
    (dex:post "https://openapi.youdao.com/api"
		 :content `(("q" . ,word)
			    ("from" . "en")
			    ("to" . "zh-CHS")
			    ("appKey" . ,app-id)
			    ("salt" . ,salt)
			    ("sign" . ,sign)
			    ("signType" . "v3")
			    ("curtime" . ,time)))))
