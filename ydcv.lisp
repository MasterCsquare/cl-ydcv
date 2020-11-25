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
		 app-id (input word) salt time app-key)))
	 (body (dex:post "https://openapi.youdao.com/api"
			 :content `(("q" . ,word)
				    ("from" . "en")
				    ("to" . "zh-CHS")
				    ("appKey" . ,app-id)
				    ("salt" . ,salt)
				    ("sign" . ,sign)
				    ("signType" . "v3")
				    ("curtime" . ,time))))
	 (result (jonathan:parse body :as :hash-table))
	 (basic (gethash "basic" result))
	 (translation (car (gethash "translation" result)))
	 (explains (gethash "explains" basic))
	 (phonetic (gethash "phonetic" basic))
	 (webs (gethash "web" result)))

    (format t "~a [~a] ~a~%" word phonetic translation)

    (format t "  Word Explanation:~%")
    (dolist (explain explains)
      (format t "     * ~a~%" explain))

    (format t "  Web Reference:~%")
    (dolist (web webs)
      (format t "     * ~a~%" (gethash "key" web))
      (format t "       ~{~a ~^~}~%" (gethash "value" web)))))
