(in-package :cl-ydcv)

(defvar *app-id* "281fc92dfed3dc9f")
(defvar *app-key* "AGlLEKYhKv8RosZ3DulAAYnZLwVMNO3A")

(defvar *cache-directory* "~/.ydcache/")
(defvar *yd-store*
  (progn
    (ensure-directories-exist *cache-directory*)
    (make-instance 'clache:file-store :directory *cache-directory*)))

(defun string-uuid ()
  (write-to-string (uuid:make-v1-uuid)))

(defun string-time-now ()
  (write-to-string (local-time:timestamp-to-unix (local-time:now))))

(defun input (q)
  (let ((length (length q)))
    (if (> length 20)
	(uiop:strcat
	 (subseq q 0 10)
	 (write-to-string length)
	 (subseq q (- length 10) length))
	q)))

(defun request-youdao (word)
  (let* ((salt (string-uuid))
	 (time (string-time-now))
	 (sign (cryptos:sha256
		(uiop:strcat
		 *app-id* (input word) salt time *app-key*))))
    (jonathan:parse
     (dex:post "https://openapi.youdao.com/api"
	       :content `(("q" . ,word)
			  ("from" . "en")
			  ("to" . "zh-CHS")
			  ("appKey" . ,*app-id*)
			  ("salt" . ,salt)
			  ("sign" . ,sign)
			  ("signType" . "v3")
			  ("curtime" . ,time))) :as :hash-table)))

(let (output)
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

	(let* ((result (request-youdao word))
	       (translation (car (gethash "translation" result)))
	       (basic (gethash "basic" result))
	       (webs (gethash "web" result)))

	  (if basic
	      (let ((explains (gethash "explains" basic))
		    (phonetic (or (gethash "phonetic" basic) "")))
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
  (let ((words (uiop:command-line-arguments)))
    (if words
	(yds words)
	(loop
	  (let ((input (rl:readline :prompt "> " :add-history t)))
	    (if input
		(yds (uiop:split-string input))
		(uiop:quit)))))))
