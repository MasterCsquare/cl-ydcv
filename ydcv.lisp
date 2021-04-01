(in-package :cl-ydcv)

(defvar app-id "281fc92dfed3dc9f")
(defvar app-key "AGlLEKYhKv8RosZ3DulAAYnZLwVMNO3A")

(defvar cache-directory "~/.ydcache/")
(defvar *yd-store*
  (progn
    (ensure-directories-exist cache-directory)
    (make-instance 'clache:file-store :directory cache-directory)))

(defun input (q)
  (let ((length (length q)))
    (if (> length 20)
	(uiop:strcat
	 (subseq q 0 10)
	 (write-to-string length)
	 (subseq q (- length 10) length))
	q)))

(let ((output))
  (defun yd-collect (control-string &rest format-arguments)
    (setf output (uiop:strcat output (apply #'format nil control-string format-arguments))))
  (defun yd-print ()
    (format t output)
    (setf output nil))
  (defun yd-output ()
    output))

(defun yd (word)
  (let ((cache (clache:getcache word *yd-store*)))
    (if cache
	(format t cache)

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
	       (basic (gethash "basic" result)))

	  (if basic
	      (let* ((translation (car (gethash "translation" result)))
		     (explains (gethash "explains" basic))
		     (phonetic (gethash "phonetic" basic))
		     (webs (gethash "web" result)))
		(yd-collect "~a [~a] ~a~%" word phonetic translation)
		(yd-collect "  Word Explanation:~%")
		(dolist (explain explains)
		  (yd-collect "     * ~a~%" explain))
		(yd-collect "  Web Reference:~%")
		(dolist (web webs)
		  (yd-collect "     * ~a~%" (gethash "key" web))
		  (yd-collect "       ~{~a ~^~}~%" (gethash "value" web)))
		(clache:setcache word (yd-output) *yd-store*)
		(yd-print))

	      (format t "~a is not a valid english word ~%" word))))))

(defun yds (words)
  (dolist (word words)
    (yd word)))

(defun ydcv ()
  (let ((words (cdr sb-ext:*posix-argv*)))
    (if words
	(yds words)
	(loop
	  (let ((input (rl:readline :prompt "> " :add-history t)))
	    (if input
		(yds (uiop:split-string input))
		(sb-ext:exit)))))))
