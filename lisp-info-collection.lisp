(ql:quickload :drakma)
(ql:quickload :yason)
(ql:quickload :alexandria)
(ql:quickload :cxml)

;デフォルトのエンコードを指定
(setf drakma:*drakma-default-external-format* :utf-8)

; ボディを文字列で取得するために、テキストとして判定される Content-Type を追加
(pushnew '("application" . "json") drakma:*text-content-types* :test #'equal)

(defvar *unix-epoch-difference*
    (encode-universal-time 0 0 0 1 1 1970 0))

(defun unix-to-universal-time (unix-time)
    (+ unix-time *unix-epoch-difference*))

(defparameter *article-bucket* (make-array 5 :fill-pointer 0 :adjustable t))

(defun date-to-universal-time (date)
  (encode-universal-time (parse-integer (subseq date 17 19)) (parse-integer (subseq date 14 16)) (parse-integer (subseq date 11 13)) (parse-integer (subseq date 8 10)) (parse-integer (subseq date 5 7)) (parse-integer (subseq date 0 4)) 9))

(defun universal-time-to-date (universal_time)
  (multiple-value-bind (sec min hr day mon year dow daylight-p zone)
      (decode-universal-time universal_time)
    (declare (ignore daylight-p zone))
    (format nil "~[Mon~;Tue~;Wed~;Thu~;Fri~;Sat~;Sun~] ~d ~[Jan~;Feb~;Mar~;Apr~;May~;Jun~;Jul~;Aug~;Sep~;Oct~;Nov~;Dec~] ~d ~2,'0d:~2,'0d:~2,'0d"
            dow
            day
            (1- mon)
            year
            hr min sec)))

;------qiita---------
(multiple-value-bind (body status)
    (drakma:http-request "https://qiita.com/api/v1/tags/common-lisp/items")
  (when (= status 200)
    (defvar *qiita-json-array* body)))

;連想配列の形をした文字列をhashtabeのベクターのs式に
(let* ((yason:*parse-json-arrays-as-vectors* t)
       (qiita-article-array (yason:parse *qiita-json-array*)))
  (defparameter *qiita-article-array* qiita-article-array))

;qiita-article-arrayから必要な情報を抽出
(loop for article across *qiita-article-array* do
  (let* ((id (gethash "id" article))
         (updated_at (gethash "updated_at" article))
         (url (gethash "url" article))
         (title (gethash "title" article))
         (user (gethash "user" article))
         (user_name (gethash "url_name" user))
         (article_table ())
         (universal_updated_at (date-to-universal-time updated_at)))
    (setf (getf article_table :article_id) id)
    (setf (getf article_table :updated_at) universal_updated_at)
    (setf (getf article_table :url) url)
    (setf (getf article_table :title) title)
    (setf (getf article_table :author_name) user_name)
    (vector-push-extend article_table *article-bucket*)))


;-------stackoverflow-----------
(multiple-value-bind (body status)
    (drakma:http-request "https://api.stackexchange.com/2.2/questions?page=1&pagesize=50&order=desc&sort=activity&tagged=common-lisp&site=stackoverflow")
  (when (= status 200)
    (defparameter *stackoverflow-json-array* body)))

(defparameter *stackoverflow-articles-array* (gethash "items" (yason:parse *stackoverflow-json-array*)))

(loop for article in *stackoverflow-articles-array* do
  (print article)
     (let ((owner (gethash "owner" article))
           (id (gethash "question_id" article))
           (is_answered (gethash "is_answered" article))
           (last_activity_date (gethash "last_activity_date" article))
           (link (gethash "link" article))
           (title (gethash "title" article))
           (article_table ()))
       (let ((author_name (gethash "display_name" owner)))
         (setf (getf article_table :article_id) id)
         (setf (getf article_table :updated_at) (unix-to-universal-time last_activity_date))
         (setf (getf article_table :url) link)
         (setf (getf article_table :title) title)
         (setf (getf article_table :author_name) author_name)
    (vector-push-extend article_table *article-bucket*))))

;---sort-----
(defparameter *sorted_article_bucket*  (sort *article-bucket* #'> :key #'(lambda (article) (getf article :updated_at))))

;------display---------
(loop for article across *sorted_article_bucket* do
  (let* ((universal_updated_at (getf article :updated_at))
        (url (getf article :url))
        (title (getf article :title))
         (author_name (getf article :author_name))
         (updated_at (universal-time-to-date universal_updated_at)))
    (format t "update_at: ~A~%user: ~A~%title: ~A~%url: ~A~%~%~%" updated_at author_name title url)))
